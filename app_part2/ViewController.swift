//
//  ViewController.swift
//  app_part2
//
//  Created by Ирина Токарева on 11.10.2021.
//

import UIKit

class ViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func nextButtonTap(_ sender: Any) {
        let viewModel = MenuVM()
        let vc = MenuCollectionVC(viewModel: viewModel)
        let navigation = UINavigationController(rootViewController: vc)
        present(navigation, animated: true)
    }
    
}

