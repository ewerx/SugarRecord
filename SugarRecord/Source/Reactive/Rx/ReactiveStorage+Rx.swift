import Foundation
import RxSwift

public extension Storage {

    func rx_operation(op: (context: Context, save: () -> Void) throws -> Void) -> Observable<Void> {
        return Observable.create { (observer) -> Disposable in
            do {
                try self.operation { (context, saver) throws -> Void in
                    try op(context: context, save: { () -> Void in
                        saver()
                    })
                    observer.onCompleted()
                }
            }
            catch {
                observer.onError(error)
            }
            return NopDisposable.instance
        }
    }
    
    func rx_operation(op: (context: Context) -> Void) -> Observable<Void> {
        return rx_operation { (context, save) in
            op(context: context)
            save()
        }
    }
    
    func rx_backgroundOperation(op: (context: Context, save: () -> Void) throws -> Void) -> Observable<Void> {
        return Observable.create { (observer) -> Disposable in
            do {
                try self.operation { (context, saver) throws in
                    try op(context: context, save: { () -> Void in
                        saver()
                    })
                    observer.onCompleted()
                }
            }
            catch {
                observer.onError(error)
            }
            return NopDisposable.instance
        }
    }
    
    func rx_backgroundOperation(op: (context: Context) throws -> Void) -> Observable<Void> {
        return rx_backgroundOperation { (context, save) throws in
            try op(context: context)
            save()
        }
    }
    
    func rx_backgroundFetch<T, U>(request: Request<T>, mapper: T -> U) -> Observable<[U]> {
        let observable: Observable<[T]> = Observable.create { (observer) -> Disposable in
            let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
            dispatch_async(dispatch_get_global_queue(priority, 0)) {
                do {
                    let results = try self.saveContext.fetch(request)
                    observer.onNext(results)
                    observer.onCompleted()
                }
                catch {
                    if let error = error as? Error {
                        observer.onError(error)
                    }
                    else {
                        observer.onNext([])
                        observer.onCompleted()
                    }
                }
            }
            return NopDisposable.instance
        }
        return observable
            .map { $0.map(mapper) }
            .observeOn(MainScheduler.instance)
    }

    func rx_fetch<T>(request: Request<T>) -> Observable<[T]> {
        return Observable.create { (observer) -> Disposable in
            do {
                try observer.onNext(self.fetch(request))
                observer.onCompleted()
            }
            catch  {
                if let error = error as? Error {
                    observer.onError(error)
                }
                else {
                    observer.onNext([])
                    observer.onCompleted()
                }
            }
            return NopDisposable.instance
        }
    }
    
}
