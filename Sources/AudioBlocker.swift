import WebKit

/// Mehrere Schichten gegen Ton:
/// 1. Inhaltsregel: Medien-Ressourcen (Audio/Video) werden nicht geladen (nur wenn Config.blockAllMedia = true)
/// 2. Skript in jedem Frame: erzwingt "muted" an allen Audio-/Video-Elementen, blockiert play(),
///    kappt Web-Audio-Ausgabe und Sprachausgabe
/// 3. WebView-Konfiguration: Wiedergabe nur nach Nutzeraktion, kein Bild-in-Bild, kein AirPlay
/// 4. Mikrofon-/Kamerazugriff wird abgelehnt (siehe BrowserModel)
enum AudioBlocker {

    static let ruleListJSON = #"""
    [
      {
        "trigger": { "url-filter": ".*", "resource-type": ["media"] },
        "action": { "type": "block" }
      }
    ]
    """#

    static let scriptTemplate = #"""
    (function () {
      'use strict';
      if (window.__noAudioInstalled) { return; }
      window.__noAudioInstalled = true;

      var PAUSE_ALL = __PAUSE_ALL__;
      var realMutedSet = null;
      var realMutedGet = null;

      function muteElement(el) {
        try {
          el.defaultMuted = true;
          if (realMutedSet && realMutedGet) {
            if (!realMutedGet.call(el)) { realMutedSet.call(el, true); }
          } else if (!el.muted) {
            el.muted = true;
          }
          if (PAUSE_ALL && !el.paused) { el.pause(); }
        } catch (e) {}
      }

      function muteAll(root) {
        try {
          var els = root.querySelectorAll('video, audio');
          for (var i = 0; i < els.length; i++) { muteElement(els[i]); }
        } catch (e) {}
      }

      // 1. HTMLMediaElement: muted erzwingen und play() abfangen
      try {
        var mediaProto = window.HTMLMediaElement && window.HTMLMediaElement.prototype;
        if (mediaProto) {
          var mutedDesc = Object.getOwnPropertyDescriptor(mediaProto, 'muted');
          if (mutedDesc && mutedDesc.get && mutedDesc.set) {
            realMutedGet = mutedDesc.get;
            realMutedSet = mutedDesc.set;
            Object.defineProperty(mediaProto, 'muted', {
              configurable: true,
              enumerable: mutedDesc.enumerable,
              get: function () { return realMutedGet.call(this); },
              set: function (v) { realMutedSet.call(this, true); }
            });
          }
          var origPlay = mediaProto.play;
          mediaProto.play = function () {
            muteElement(this);
            if (PAUSE_ALL) {
              return Promise.reject(new DOMException('Wiedergabe deaktiviert', 'NotAllowedError'));
            }
            return origPlay.apply(this, arguments);
          };
        }
      } catch (e) {}

      // 2. Ereignisse: sobald etwas abspielt oder die Lautstärke geändert wird, wieder stumm schalten
      ['play', 'playing', 'volumechange', 'loadedmetadata', 'canplay'].forEach(function (type) {
        document.addEventListener(type, function (e) {
          var t = e.target;
          if (t && t.tagName && (t.tagName === 'VIDEO' || t.tagName === 'AUDIO')) { muteElement(t); }
        }, true);
      });

      // 3. Neue Elemente sofort stumm schalten, dazu regelmäßige Kontrolle
      try {
        new MutationObserver(function (records) {
          for (var i = 0; i < records.length; i++) {
            var added = records[i].addedNodes;
            for (var j = 0; j < added.length; j++) {
              var n = added[j];
              if (n.nodeType !== 1) { continue; }
              if (n.tagName === 'VIDEO' || n.tagName === 'AUDIO') { muteElement(n); }
              else if (n.querySelectorAll) { muteAll(n); }
            }
          }
        }).observe(document, { childList: true, subtree: true });
      } catch (e) {}
      setInterval(function () { muteAll(document); }, 1000);

      // 4. Web Audio: Verbindungen zum Ausgang kappen
      try {
        var NodeProto = window.AudioNode && window.AudioNode.prototype;
        var DestCtor = window.AudioDestinationNode;
        if (NodeProto && DestCtor) {
          var origConnect = NodeProto.connect;
          NodeProto.connect = function (target) {
            if (target instanceof DestCtor) { return target; }
            return origConnect.apply(this, arguments);
          };
        }
        ['AudioContext', 'webkitAudioContext'].forEach(function (name) {
          var Ctx = window[name];
          if (Ctx && Ctx.prototype && Ctx.prototype.resume) {
            Ctx.prototype.resume = function () { return Promise.resolve(); };
          }
        });
      } catch (e) {}

      // 5. Sprachausgabe
      try {
        if (window.SpeechSynthesis && window.SpeechSynthesis.prototype) {
          window.SpeechSynthesis.prototype.speak = function () {};
        }
      } catch (e) {}
    })();
    """#

    static func install(in controller: WKUserContentController, completion: @escaping () -> Void) {
        let source = scriptTemplate.replacingOccurrences(
            of: "__PAUSE_ALL__",
            with: Config.blockAllMedia ? "true" : "false"
        )
        let userScript = WKUserScript(
            source: source,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        controller.addUserScript(userScript)

        guard Config.blockAllMedia else {
            completion()
            return
        }

        let optionalStore: WKContentRuleListStore? = WKContentRuleListStore.default()
        guard let store = optionalStore else {
            completion()
            return
        }

        store.compileContentRuleList(
            forIdentifier: "BlockMedia",
            encodedContentRuleList: ruleListJSON
        ) { list, _ in
            DispatchQueue.main.async {
                if let list = list {
                    controller.add(list)
                }
                completion()
            }
        }
    }
}
