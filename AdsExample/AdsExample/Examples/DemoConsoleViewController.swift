import AdMasterSDK
import UIKit

class DemoConsoleViewController: UIViewController {
    let contentView = UIView()
    let showButton = UIButton(type: .system)
    
    private let logPanelView = UIView()
    private let logTitleLabel = UILabel()
    private let logTableView = UITableView(frame: .zero, style: .plain)
    private var logLines: [String] = []
    private var errorRows = Set<Int>()
    private var collapsedConstraint: NSLayoutConstraint?
    private var pinnedConstraint: NSLayoutConstraint?
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        installDemoConsole()
    }
    
    // MARK: - Layout
    
    func installDemoConsole() {
        guard contentView.superview == nil else { return }
        
        view.backgroundColor = .white
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = UIColor(white: 0.96, alpha: 1)
        
        logPanelView.translatesAutoresizingMaskIntoConstraints = false
        logPanelView.backgroundColor = .white
        
        logTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        logTitleLabel.text = "Event Log"
        logTitleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        logTitleLabel.textColor = UIColor(white: 0.55, alpha: 1)
        
        logTableView.translatesAutoresizingMaskIntoConstraints = false
        logTableView.dataSource = self
        logTableView.separatorInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
        logTableView.rowHeight = UITableView.automaticDimension
        logTableView.estimatedRowHeight = 36
        logTableView.tableFooterView = UIView()
        
        showButton.translatesAutoresizingMaskIntoConstraints = false
        showButton.backgroundColor = UIColor(red: 0, green: 0.48, blue: 1, alpha: 1)
        showButton.setTitle("Show", for: .normal)
        showButton.setTitleColor(.white, for: .normal)
        showButton.titleLabel?.font = .boldSystemFont(ofSize: 17)
        showButton.layer.cornerRadius = 10
        
        view.addSubview(contentView)
        view.addSubview(logPanelView)
        view.addSubview(showButton)
        logPanelView.addSubview(logTitleLabel)
        logPanelView.addSubview(logTableView)
        
        collapsedConstraint = contentView.bottomAnchor.constraint(equalTo: contentView.topAnchor)
        collapsedConstraint?.isActive = true
        
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: safe.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            logPanelView.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 16),
            logPanelView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            logPanelView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            logPanelView.bottomAnchor.constraint(equalTo: showButton.topAnchor, constant: -16),
            logPanelView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            
            logTitleLabel.topAnchor.constraint(equalTo: logPanelView.topAnchor, constant: 12),
            logTitleLabel.leadingAnchor.constraint(equalTo: logPanelView.leadingAnchor, constant: 12),
            logTitleLabel.trailingAnchor.constraint(equalTo: logPanelView.trailingAnchor, constant: -12),
            
            logTableView.topAnchor.constraint(equalTo: logTitleLabel.bottomAnchor, constant: 8),
            logTableView.leadingAnchor.constraint(equalTo: logPanelView.leadingAnchor),
            logTableView.trailingAnchor.constraint(equalTo: logPanelView.trailingAnchor),
            logTableView.bottomAnchor.constraint(equalTo: logPanelView.bottomAnchor),
            
            showButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            showButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            showButton.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -8),
            showButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    func pinContentBottom(to view: UIView, constant: CGFloat = 0) {
        collapsedConstraint?.isActive = false
        pinnedConstraint?.isActive = false
        pinnedConstraint = contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: constant)
        pinnedConstraint?.isActive = true
    }
    
    // MARK: - Logging
    
    func log(_ message: String) {
        append(message, isError: false)
    }
    
    func logCall(_ message: String) {
        log("[Call] \(message)")
    }
    
    func logCallback(function: String = #function) {
        log("[Callback] \(function)")
    }
    
    func logError(_ error: Error?, function: String = #function) {
        let nsError = error as NSError?
        let serverCode = nsError?.userInfo[ADMServerErrorCodeKey] as? String
        let code = nsError.map { "\($0.code)" } ?? "-"
        let prefix = serverCode?.isEmpty == false ? "[\(code)/S\(serverCode!)]" : "[\(code)]"
        let desc = nsError?.localizedDescription ?? "Unknown error"
        append("[Callback] \(function): \(prefix) \(desc)", isError: true)
    }
    
    func logFailure(_ message: String) {
        append(message, isError: true)
    }
    
    private func append(_ body: String, isError: Bool) {
        NSLog("[Demo] %@", body)
        DispatchQueue.main.async {
            let row = self.logLines.count
            self.logLines.append("\(self.formatter.string(from: Date()))  \(body)")
            if isError {
                self.errorRows.insert(row)
            }
            let indexPath = IndexPath(row: row, section: 0)
            self.logTableView.insertRows(at: [indexPath], with: .none)
            self.logTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource

extension DemoConsoleViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        logLines.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DemoLogCell") ??
        UITableViewCell(style: .default, reuseIdentifier: "DemoLogCell")
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont(name: "Menlo-Regular", size: 13) ?? .systemFont(ofSize: 13)
        cell.textLabel?.textColor = errorRows.contains(indexPath.row) ? .systemRed : UIColor(white: 0.15, alpha: 1)
        cell.textLabel?.text = logLines[indexPath.row]
        return cell
    }
}
