import SwiftUI
import GoogleMobileAds

// NativeAdWidget - SwiftUI wrapper for NativeAdView
// Note: No typealiases needed - GoogleMobileAds SDK v11+ uses non-GAD names natively
struct NativeAdWidget: UIViewRepresentable {
    let nativeAd: NativeAd
    
    func makeUIView(context: Context) -> NativeAdView {
        let view = NativeAdView()
        
        // UI Components
        let iconImageView = UIImageView()
        let headlineLabel = UILabel()
        let bodyLabel = UILabel()
        let callActionButton = UIButton()
        let advertiserLabel = UILabel()
        
        // Styling
        view.backgroundColor = UIColor(Color.slate800)
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        
        // Icon
        iconImageView.layer.cornerRadius = 8
        iconImageView.clipsToBounds = true
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Headline
        headlineLabel.textColor = .white
        headlineLabel.font = .systemFont(ofSize: 15, weight: .bold)
        headlineLabel.numberOfLines = 1
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Body
        bodyLabel.textColor = UIColor(Color.slate400)
        bodyLabel.font = .systemFont(ofSize: 12)
        bodyLabel.numberOfLines = 2
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Advertiser
        advertiserLabel.textColor = UIColor(Color.slate400)
        advertiserLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        advertiserLabel.text = "Ad"
        advertiserLabel.layer.borderColor = UIColor(Color.slate400).cgColor
        advertiserLabel.layer.borderWidth = 1
        advertiserLabel.layer.cornerRadius = 4
        advertiserLabel.textAlignment = .center
        advertiserLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Call to Action
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = UIColor(Color.admobBlue)
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        callActionButton.configuration = config
        callActionButton.translatesAutoresizingMaskIntoConstraints = false
        callActionButton.isUserInteractionEnabled = false
        
        // Hierarchy
        view.addSubview(iconImageView)
        view.addSubview(headlineLabel)
        view.addSubview(bodyLabel)
        view.addSubview(callActionButton)
        view.addSubview(advertiserLabel)
        
        // Constraints
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            iconImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40),
            
            headlineLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            headlineLabel.topAnchor.constraint(equalTo: iconImageView.topAnchor),
            headlineLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            
            advertiserLabel.leadingAnchor.constraint(equalTo: iconImageView.leadingAnchor),
            advertiserLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            advertiserLabel.widthAnchor.constraint(equalToConstant: 24),
            advertiserLabel.heightAnchor.constraint(equalToConstant: 16),
            
            bodyLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
            bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 2),
            bodyLabel.trailingAnchor.constraint(equalTo: callActionButton.leadingAnchor, constant: -8),
            
            callActionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            callActionButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            callActionButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        // Register Views
        view.nativeAd = nativeAd
        view.iconView = iconImageView
        view.headlineView = headlineLabel
        view.bodyView = bodyLabel
        view.callToActionView = callActionButton
        view.advertiserView = advertiserLabel
        
        // Populate
        (view.headlineView as? UILabel)?.text = nativeAd.headline
        (view.bodyView as? UILabel)?.text = nativeAd.body
        (view.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        view.iconView?.isHidden = nativeAd.icon == nil
        (view.iconView as? UIImageView)?.image = nativeAd.icon?.image
        
        return view
    }
    
    func updateUIView(_ uiView: NativeAdView, context: Context) {}
}
