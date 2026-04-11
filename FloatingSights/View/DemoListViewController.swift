//
//  DemoListViewController.swift
//  FloatingSights
//
//  Created by takedatakashiki on 2026/04/11.
//

import UIKit

final class DemoListViewController: UITableViewController {
    // MARK: - Data

    private let demos: [(title: String, makeVC: @MainActor () -> UIViewController)] = [
        ("AR", { ARSceneViewController() }),
        ("シェーダー", { ShaderPreviewViewController() }),
    ]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "FloatingSights"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        demos.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = demos[indexPath.row].title
        config.textProperties.font = .systemFont(ofSize: 20, weight: .medium)
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = demos[indexPath.row].makeVC()
        navigationController?.pushViewController(vc, animated: true)
    }
}
