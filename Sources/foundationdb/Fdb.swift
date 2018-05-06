/**
 * Copyright Nuno Maia 2018
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation
import CFoundationdb


/// The starting point for accessing FoundationDB.
///
/// The foundationdb API is accessed with a call to selectAPIVersion(int).
/// This call is required before using any other part of the API. The call allows
/// an error to be thrown at this point to prevent client code from accessing a later library
/// with incorrect assumptions from the current version. The API version documented here is version 510
///
/// FoundationDB encapsulates multiple versions of its interface by requiring
/// the client to explicitly specify the version of the API it uses. The purpose
/// of this design is to allow you to upgrade the server, client libraries, or
/// bindings without having to modify client code. The client libraries support
/// all previous versions of the API. The API version specified by the client is
/// used to control the behavior of the binding. You can therefore upgrade to
/// more recent packages (and thus receive various improvements) without having
/// to change your code.
///
///  Warning: When using the multi-version client API, setting an API version that
///  is not supported by a particular client library will prevent that client from
///  being used to connect to the cluster. In particular, you should not advance
///  the API version of your application after upgrading your client until the
///  cluster has also been upgraded.
///
///  Once the API version has been set, the easiest way to get a Database} object to use is
///  to call open.
///
///  Client networking
///  The network is started either implicitly with a call to a variant of open or
///  createCluster(), or started explicitly with a call to startNetwork().
///
///

class Fdb {
    
    /// Minimum supported API version
    static let ApiMinVersion : Int32 = 13
    
    /// Maximum supported API version
    static let ApiMaxVersion : Int32 = 510
    
    /// C Header defined version
    static let FdbApiVersion : Int32 = 510
    
    /// API version that was selected by the selectAPIVersion()
    /// call. This can be used to guard different parts of client code against different versions
    /// of the FoundationDB API to allow for libraries using FoundationDB to be compatible across
    /// several versions.
    let apiVersion : Int32
    
    private(set) var netStarted = false
    private(set) var netStopped = false
    
    private static var singleton : Fdb? = nil
    
    private static let staticLock = DispatchSemaphore(value: 1)
    
    private let instanceLock = DispatchSemaphore(value: 1)
    private let netLock = DispatchSemaphore(value: 1)
    
    private var runNetworkWorkItem : DispatchWorkItem?
    
    private let execQueue = DispatchQueue(label: "concurrentQueue", qos: .utility, attributes: .concurrent)
    
    /// Called only once to create the FDB singleton.
    private init(apiVersion : Int32) {
        self.apiVersion = apiVersion
    }
    
    /// Determines if the API version has already been selected. That is, this
    ///  will return true. if the user has already called
    ///  selectAPIVersion(int) selectAPIVersion() and that call
    ///  has completed successfully.
    ///
    /// - returns: true if an API version has been selected and false otherwise
    func isAPIVersionSelected() -> Bool {
        return Fdb.singleton != nil;
    }
    
     /// Return the instance of the FDB API singleton. This method will always return
     ///  a non null value for the singleton, but if the
     ///  selectAPIVersion() method has not yet been
     ///  called, it will throw an eException indicating that an API
     ///  version has not yet been set.
     ///
     /// - returns: the FoundationDB API object
     /// - throws: FDBException if selectAPIVersion() has not been called
     static func instance() throws -> Fdb {
        
        guard let singleton = Fdb.singleton else {
            throw FdbError.APIVersionNotSet
        }
        
        return singleton;
    }
    
    /// Select the max version for the client API. An exception will be thrown if the
    /// requested version is not supported by this implementation of the API. As
    /// only one version can be selected for the lifetime of the program, the result
    /// of a successful call to this method is always the same instance of a Fdb
    /// object.
    ///
    /// Warning: When using the multi-version client API, setting an API version that
    /// is not supported by a particular client library will prevent that client from
    /// being used to connect to the cluster. In particular, you should not advance
    /// the API version of your application after upgrading your client until the
    /// cluster has also been upgraded.
    ///
    /// - returns: the FoundationDB API object
    static func selectMaxApiVersion() throws -> Fdb {
        return try selectAPIVersion(version : ApiMaxVersion)
    }
    
    /// Select the version for the client API. An exception will be thrown if the
    /// requested version is not supported by this implementation of the API. As
    /// only one version can be selected for the lifetime of the program, the result
    /// of a successful call to this method is always the same instance of a Fdb
    /// object.
    ///
    /// Warning: When using the multi-version client API, setting an API version that
    /// is not supported by a particular client library will prevent that client from
    /// being used to connect to the cluster. In particular, you should not advance
    /// the API version of your application after upgrading your client until the
    /// cluster has also been upgraded.
    ///
    /// - parameter version: version the API version required
    ///
    /// - returns: the FoundationDB API object
    static func selectAPIVersion(version : Int32) throws -> Fdb {
        
        staticLock.wait()
        
        defer {
            staticLock.signal()
        }
        
        if let singleton = Fdb.singleton {
            guard version == singleton.apiVersion else {
                throw FdbError.APIDifferentVersionStarted
            }
        }
        
        guard version > ApiMinVersion || version < ApiMaxVersion else {
            throw FdbError.apiVersionNotSupported
        }
        
        let err = fdb_select_api_version_impl(version,FdbApiVersion)
        
        guard err == 0 else {
            throw FdbError.fdbApiError(err, nil)
        }
        
        singleton = Fdb(apiVersion: version)
        return singleton!;
    }
    
    /// Connects to the cluster specified by the
    /// default fdb.cluster file
    /// If the FoundationDB network has not been started, it will be started in the course of this call
    /// as if startNetwork() had been called.
    ///
    /// - returns: a CompletableFuture that will be set to a FoundationDB Cluster.
    /// - throws: FDBException on errors encountered starting the FoundationDB networking engine
    /// IllegalStateException if the network had been previously stopped
    func createCluster() throws -> Cluster {
        return try createCluster(clusterFilePath : nil);
    }
    
    ///
    /// Connects to the cluster specified by the default fdb.cluster file
    /// If the FoundationDB network has not been started, it will be started in the course of this call
    /// as if startNetwork() had been called.
    /// - returns: a CompletableFuture that will be set to a FoundationDB Cluster.
    /// - throws: On errors encountered starting the FoundationDB networking engine or if
    /// if the network had been previously stopped
    func createCluster(clusterFilePath : String?) throws -> Cluster {
        
        instanceLock.wait()
        
        defer {
            instanceLock.signal()
        }
        
        if (!isConnected()) {
            try startNetwork()
        }
        
        guard let future = fdb_create_cluster(clusterFilePath) else {
                throw FdbError.fdbApiError(0, nil)
        }
        
        let futureCluster = try Future(future)
        try futureCluster.wait()
        
        var clusterPointer : OpaquePointer?
        
        let err = fdb_future_get_cluster(future, &clusterPointer)
            
        guard err != 0 else {
                throw FdbError.fdbApiError(err, nil)
        }
        
        fdb_future_destroy(clusterPointer!)
        
        return Cluster(clusterPointer: clusterPointer!)
    }
    
    
    /// Initializes networking, connects with the
    /// default fdb.cluster file and opens the database.
    /// - returns: A CompletableFuture that will be set to a FoundationDB Database
    func open() throws -> Database {
        return try open(clusterFilePath: nil);
    }
    
    /// Initializes networking, connects to the cluster specified by clusterFilePath
    /// and opens the database.
    ///
    /// - parameter: clusterFilePath the cluster file defining the FoundationDB cluster.
    /// if paramter is nill. the default fdb.cluster file file will be used.
    /// - returns: a CompletableFuture that will be set to a FoundationDB Cluster.
    func open(clusterFilePath: String?) throws -> Database {
        return Database()
        //TODO
    }
    
    private func startNetworkWorkItem() {
        netLock.wait()
        
        guard !netStopped else {
            return
        }
        
        let err = fdb_run_network()
        guard err != 0 else {
            NSLog("Unhandled error in FoundationDB network thread: %v (%v)\n", err)
            return
        }
        
        defer {
            netLock.signal()
        }
    }
    
    private func startNetwork() throws {
        
        guard !netStopped else {
            throw FdbError.NetworkIsStopped
        }
        
        guard netStarted else {
            return
        }
        
        let err = fdb_setup_network()
        guard err == 0 else {
            throw FdbError.fdbApiError(err, "fdb_setup_network")
        }
        
        runNetworkWorkItem = DispatchWorkItem {
            self.startNetworkWorkItem()
        }
        
        execQueue.async(execute: runNetworkWorkItem!)
        
        netStarted = true
    }
    
    /// Gets the state of the FoundationDB networking thread.
    /// - returns: true if the FDB network thread is running, false otherwise.
    func isConnected() -> Bool {
        return netStarted && !netStopped
    }
}
