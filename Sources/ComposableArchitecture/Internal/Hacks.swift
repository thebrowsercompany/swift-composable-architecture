import OpenCombineShim

#if canImport(Combine)
    typealias CombineSubscription = Combine.Subscription
    public typealias CombineSubscriber = Combine.Subscriber
#else
    typealias CombineSubscription = OpenCombine.Subscription
    public typealias CombineSubscriber = OpenCombine.Subscriber

    let NSEC_PER_MSEC: UInt64 = 1_000_000
    let NSEC_PER_SEC: UInt64 = 1_000_000_000
#endif
