import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))
        
        let summaryVC = SummaryViewController()
        let summaryNav = UINavigationController(rootViewController: summaryVC)
        summaryNav.tabBarItem = UITabBarItem(title: "Summary", image: UIImage(systemName: "chart.pie"), selectedImage: UIImage(systemName: "chart.pie.fill"))
        
        let settingsVC = SettingsViewController(style: .grouped)
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape"), selectedImage: UIImage(systemName: "gearshape.fill"))
        
        viewControllers = [homeNav, summaryNav, settingsNav]
        
        // Tab Bar Styling (Backward Compatible)
        tabBar.barTintColor = .systemBackground
        tabBar.isTranslucent = true
        tabBar.tintColor = Theme.accent
    }
}
