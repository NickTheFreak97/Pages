import UIKit

@objc(HYPPagesControllerDelegate)
public protocol PagesControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        fromViewController startingViewController: UIViewController?,
        setViewController viewController: UIViewController,
        atPage page: Int
    )
}

@objc(HYPPagesController)
open class PagesController: UIPageViewController {

    private struct Dimensions {
        static let bottomLineHeight: CGFloat = 1.0
        static let bottomLineSideMargin: CGFloat = 40.0
        static let bottomLineBottomMargin: CGFloat = 36.0
        static let pageControlBottomMargin: CGFloat = 8.0
    }

    public let startPage = 0
    public var setNavigationTitle = true

    public var enableSwipe = true {
        didSet {
            toggle()
        }
    }

    public var showBottomLine = false {
        didSet {
            bottomLineView.isHidden = !showBottomLine
        }
    }

    public var showPageControl = true {
        didSet {
            updatePageControl()
            updateBottomControlsInset()
        }
    }

    public var pagesCount: Int {
        pages.count
    }

    public private(set) var currentIndex = 0

    public weak var pagesDelegate: PagesControllerDelegate?

    public private(set) var bottomControlsInset: CGFloat = 0

    public var onBottomControlsInsetChanged: ((CGFloat) -> Void)?

    public private(set) lazy var bottomLineView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.alpha = 0.4
        view.isHidden = true
        return view
    }()

    public private(set) lazy var pageControl: UIPageControl = {
        let control = UIPageControl()

        control.translatesAutoresizingMaskIntoConstraints = false
        control.backgroundColor = .clear
        control.isOpaque = false
        control.hidesForSinglePage = true

        if #available(iOS 14.0, *) {
            control.backgroundStyle = .minimal
        }

        return control
    }()

    private lazy var pages = Array<UIViewController>()

    public convenience init(
        _ pages: [UIViewController],
        transitionStyle: UIPageViewController.TransitionStyle = .scroll,
        navigationOrientation: UIPageViewController.NavigationOrientation = .horizontal,
        options: [UIPageViewController.OptionsKey: Any]? = nil
    ) {
        self.init(
            transitionStyle: transitionStyle,
            navigationOrientation: navigationOrientation,
            options: options
        )

        add(pages)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        dataSource = self

        view.addSubview(bottomLineView)
        view.addSubview(pageControl)

        addConstraints()

        view.bringSubviewToFront(bottomLineView)
        view.bringSubviewToFront(pageControl)

        updatePageControlAppearance()
        goTo(startPage)
        updatePageControl()
        updateBottomControlsInset()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        view.bringSubviewToFront(bottomLineView)
        view.bringSubviewToFront(pageControl)

        updateBottomControlsInset()
    }

    open override func traitCollectionDidChange(
        _ previousTraitCollection: UITraitCollection?
    ) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard
            previousTraitCollection?.userInterfaceStyle
                != traitCollection.userInterfaceStyle
        else {
            return
        }

        updatePageControlAppearance()
    }

    open func goTo(_ index: Int) {
        guard index >= 0 && index < pages.count else {
            return
        }

        guard index != currentIndex else {
            return
        }

        let direction: UIPageViewController.NavigationDirection =
            index > currentIndex ? .forward : .reverse

        let current = pages[currentIndex]
        let viewController = pages[index]

        currentIndex = index

        setViewControllers(
            [viewController],
            direction: direction,
            animated: true,
            completion: { [weak self] _ in
                guard let self else {
                    return
                }

                self.pagesDelegate?.pageViewController(
                    self,
                    fromViewController: current,
                    setViewController: viewController,
                    atPage: self.currentIndex
                )
            }
        )

        if setNavigationTitle {
            title = viewController.title
        }

        updatePageControl()
    }

    @objc open func moveForward() {
        goTo(currentIndex + 1)
    }

    @objc open func moveBack() {
        goTo(currentIndex - 1)
    }

    open func add(_ viewControllers: [UIViewController]) {
        for viewController in viewControllers {
            addViewController(viewController)
        }
    }
}

extension PagesController: UIPageViewControllerDataSource {

    @objc open func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        let index = prevIndex(viewControllerIndex(viewController))
        return pages.at(index)
    }

    @objc open func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        let index = nextIndex(viewControllerIndex(viewController))
        return pages.at(index)
    }

    @objc open func presentationCount(
        for pageViewController: UIPageViewController
    ) -> Int {
        0
    }

    @objc open func presentationIndex(
        for pageViewController: UIPageViewController
    ) -> Int {
        0
    }
}

extension PagesController: UIPageViewControllerDelegate {

    @objc open func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed else {
            return
        }

        guard let viewController = pageViewController.viewControllers?.last else {
            return
        }

        guard let index = viewControllerIndex(viewController) else {
            return
        }

        let currentViewController = pages[currentIndex]

        currentIndex = index

        if setNavigationTitle {
            title = viewController.title
        }

        updatePageControl()
        updateBottomControlsInset()

        pagesDelegate?.pageViewController(
            self,
            fromViewController: currentViewController,
            setViewController: pages[currentIndex],
            atPage: currentIndex
        )
    }
}

private extension PagesController {

    func viewControllerIndex(
        _ viewController: UIViewController
    ) -> Int? {
        pages.firstIndex(of: viewController)
    }

    func toggle() {
        for subview in view.subviews {
            if let subview = subview as? UIScrollView {
                subview.isScrollEnabled = enableSwipe
                break
            }
        }
    }

    private func updatePageControlAppearance() {
        let color: UIColor

        if #available(iOS 13.0, *) {
            color = traitCollection.userInterfaceStyle == .dark
                ? .white
                : .black
        } else {
            color = .black
        }

        pageControl.pageIndicatorTintColor = color.withAlphaComponent(0.25)
        pageControl.currentPageIndicatorTintColor = color.withAlphaComponent(0.9)

        if #available(iOS 14.0, *) {
            pageControl.backgroundStyle = .minimal
        }

        pageControl.setNeedsDisplay()
        pageControl.setNeedsLayout()
    }



    func updatePageControl() {
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = currentIndex
        pageControl.isHidden = !showPageControl || pages.count <= 1
    }

    func updateBottomControlsInset() {
        guard showPageControl, !pageControl.isHidden else {
            updateBottomControlsInset(to: 0)
            return
        }

        pageControl.layoutIfNeeded()

        let frame = pageControl.convert(
            pageControl.bounds,
            to: view
        )

        let inset = max(
            0,
            view.bounds.maxY - frame.minY
        )

        updateBottomControlsInset(to: inset)
    }

    func updateBottomControlsInset(to value: CGFloat) {
        guard abs(bottomControlsInset - value) > 0.5 else {
            return
        }

        bottomControlsInset = value
        onBottomControlsInsetChanged?(value)
    }

    func addViewController(
        _ viewController: UIViewController
    ) {
        pages.append(viewController)

        guard pages.count == 1 else {
            return
        }

        setViewControllers(
            [viewController],
            direction: .forward,
            animated: true,
            completion: { [weak self] _ in
                guard let self else {
                    return
                }

                self.pagesDelegate?.pageViewController(
                    self,
                    fromViewController: nil,
                    setViewController: viewController,
                    atPage: self.currentIndex
                )
            }
        )

        if setNavigationTitle {
            title = viewController.title
        }
    }

    func addConstraints() {
        NSLayoutConstraint.activate([
            bottomLineView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -Dimensions.bottomLineBottomMargin
            ),
            bottomLineView.leftAnchor.constraint(
                equalTo: view.leftAnchor,
                constant: Dimensions.bottomLineSideMargin
            ),
            bottomLineView.rightAnchor.constraint(
                equalTo: view.rightAnchor,
                constant: -Dimensions.bottomLineSideMargin
            ),
            bottomLineView.heightAnchor.constraint(
                equalToConstant: Dimensions.bottomLineHeight
            ),

            pageControl.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            pageControl.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -Dimensions.pageControlBottomMargin
            )
        ])
    }
}

extension PagesController {

    public convenience init(
        _ storyboardIds: [String],
        storyboard: UIStoryboard = .Main
    ) {
        let pages = storyboardIds.map(
            storyboard.instantiateViewController(withIdentifier:)
        )

        self.init(pages)
    }
}
