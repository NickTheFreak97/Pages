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
            pageControl?.isHidden = !showPageControl
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
        view.backgroundColor = UIColor.white
        view.alpha = 0.4
        view.isHidden = true
        return view
    }()

    public private(set) var pageControl: UIPageControl?

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

        addConstraints()

        view.bringSubviewToFront(bottomLineView)

        goTo(startPage)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        findPageControl()
        updateBottomControlsInset()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateBottomControlsInset()
    }

    open func goTo(_ index: Int) {
        guard index >= 0 && index < pages.count else {
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
        showPageControl ? pages.count : 0
    }

    @objc open func presentationIndex(
        for pageViewController: UIPageViewController
    ) -> Int {
        showPageControl ? currentIndex : 0
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

        pageControl?.currentPage = currentIndex

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

    func findPageControl() {
        guard pageControl == nil else {
            return
        }

        for subview in view.subviews {
            if let pageControl = subview as? UIPageControl {
                self.pageControl = pageControl
                break
            }
        }
    }

    func updateBottomControlsInset() {
        findPageControl()

        guard let pageControl else {
            updateBottomControlsInset(to: 0)
            return
        }

        guard showPageControl else {
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
        view.addConstraint(
            NSLayoutConstraint(
                item: bottomLineView,
                attribute: .bottom,
                relatedBy: .equal,
                toItem: view,
                attribute: .bottom,
                multiplier: 1,
                constant: -Dimensions.bottomLineBottomMargin
            )
        )

        view.addConstraint(
            NSLayoutConstraint(
                item: bottomLineView,
                attribute: .left,
                relatedBy: .equal,
                toItem: view,
                attribute: .left,
                multiplier: 1,
                constant: Dimensions.bottomLineSideMargin
            )
        )

        view.addConstraint(
            NSLayoutConstraint(
                item: bottomLineView,
                attribute: .right,
                relatedBy: .equal,
                toItem: view,
                attribute: .right,
                multiplier: 1,
                constant: -Dimensions.bottomLineSideMargin
            )
        )

        view.addConstraint(
            NSLayoutConstraint(
                item: bottomLineView,
                attribute: .height,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1,
                constant: Dimensions.bottomLineHeight
            )
        )
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
