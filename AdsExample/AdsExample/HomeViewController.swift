import AdMasterSDK
import UIKit

final class HomeViewController: UITableViewController {
    private enum Section: Int, CaseIterable {
        case ads
        case idfa
        case mock
        case version
    }
    
    private let adItems: [(String, UIViewController.Type)] = [
        ("App Open", AppOpenAdViewController.self),
        ("Banner", BannerAdViewController.self),
        ("Interstitial", InterstitialAdViewController.self),
        ("Rewarded", RewardedAdViewController.self),
        ("Native", NativeAdViewController.self)
    ]
    private var idfa = "Loading..."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "AdMasterSDK Demo"
        tableView.backgroundColor = .systemGroupedBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        IDFAManager.requestIfNeeded(delay: true) { [weak self] idfa in
            self?.idfa = idfa
            self?.tableView.reloadSections(IndexSet(integer: Section.idfa.rawValue), with: .none)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .ads:
            return adItems.count
        case .idfa, .mock, .version:
            return 1
        case .none:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .ads:
            return "Ad Types"
        case .idfa:
            return "IDFA (tap to copy)"
        case .mock:
            return "Mock Mode"
        case .version:
            return "SDK Version"
        case .none:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.textProperties.numberOfLines = 2
        cell.accessoryView = nil
        cell.accessoryType = .none
        cell.selectionStyle = .default
        
        switch Section(rawValue: indexPath.section) {
        case .ads:
            config.text = adItems[indexPath.row].0
            cell.accessoryType = .disclosureIndicator
        case .idfa:
            config.text = idfa
        case .mock:
            config.text = "Debug only. Returns fixed test ads."
            cell.selectionStyle = .none
            let control = UISwitch()
            control.isOn = UserDefaults.standard.bool(forKey: SampleConfig.mockModeKey)
            control.addTarget(self, action: #selector(mockChanged(_:)), for: .valueChanged)
            cell.accessoryView = control
        case .version:
            config.text = ADMSetting.sharedInstance().getSDKVersion()
            cell.selectionStyle = .none
        case .none:
            break
        }
        
        cell.contentConfiguration = config
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Section(rawValue: indexPath.section) {
        case .ads:
            let viewController = adItems[indexPath.row].1.init()
            navigationController?.pushViewController(viewController, animated: true)
        case .idfa:
            IDFAManager.requestIfNeeded(delay: false) { [weak self] idfa in
                self?.idfa = idfa
                UIPasteboard.general.string = idfa
                self?.tableView.reloadSections(IndexSet(integer: Section.idfa.rawValue), with: .none)
                self?.showAlert(title: "IDFA Copied", message: idfa)
            }
        default:
            break
        }
    }
    
    // MARK: - Actions
    
    @objc private func mockChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: SampleConfig.mockModeKey)
        ADMSetting.sharedInstance().isMock = sender.isOn
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
