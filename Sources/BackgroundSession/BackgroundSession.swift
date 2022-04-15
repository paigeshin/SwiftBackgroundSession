import AVFoundation
import CallKit
import Combine

// MARK: RESPONSIBLE FOR MAKING APP ALIVE IN THE BACKGROUND
// MARK: HANDLE CALL RECEIVE EVENT
#if !os(macOS)
protocol TrackingSession {
    var callEndedEvent: PassthroughSubject<Bool, Never> { get }
    func keepAlive()
}

public class TrackingSessionImpl: NSObject, TrackingSession, CXCallObserverDelegate {

    private(set) var callEndedEvent: PassthroughSubject<Bool, Never> = PassthroughSubject()
    private var player: AVPlayer?
    private let callObserver: CXCallObserver = CXCallObserver()
    
    override init() {
        super.init()
        callObserver.setDelegate(self, queue: nil)
    }
    
    public func keepAlive() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                AVAudioSession.Category.playback,
                mode: AVAudioSession.Mode.default,
                options: [.mixWithOthers, .allowAirPlay]
            )
        } catch {
            print(error.localizedDescription)
        }

        guard let url = Bundle.main.url(forResource: "session", withExtension: "m4a") else {
            #if DEBUG
            print("Session Activation Failed...")
            #endif
            return
        }
        #if DEBUG
        print("Successfully Activated Background Session")
        #endif
        player = AVPlayer(url: url)
        // - muted version
        player?.isMuted = true
        player?.play()
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: .main) { [weak self] _ in
            self?.player?.seek(to: CMTime.zero)
            self?.player?.play()
        }
    }
    
    public func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        if call.hasEnded == true {
            #if DEBUG
            print("Disconnected")
            #endif 
            keepAlive()
            callEndedEvent.send(true)
        }
        if call.isOutgoing == true && call.hasConnected == false {
            #if DEBUG
            print("Dialing")
            #endif
        }
        if call.isOutgoing == false && call.hasConnected == false && call.hasEnded == false {
            #if DEBUG
            print("Incoming")
            #endif
        }

        if call.hasConnected == true && call.hasEnded == false {
            #if DEBUG
            print("Connected")
            #endif
        }
    }
}
#endif
