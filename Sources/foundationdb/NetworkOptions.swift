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

/// Defines a set of options for the network thread
enum NetworkOption : Int32 {

    // Enables trace output to a file in a directory of the clients choosing
    // Parameter: (String) path to output directory (or NULL for current working directory)
    case traceEnable = 30

    // Sets the maximum size in bytes of a single trace output file. This value should be in
    /// the range``[0,INT64_MAX]``. If the value is set to 0, there is no limit on individual file size.
    /// The default is a maximum size of 10,485,760 bytes.
    // Parameter: (Int) max size of a single trace output file
    case traceRollSize = 31

    /// Sets the maximum size of all the trace output files put together. This value should be
    /// in the range ``[0, INT64_MAX]``. If the value is set to 0, there is no limit on the total size
    ///of the files. The default is a maximum size of 104,857,600 bytes. If the default roll size is used,
    ///this means that a maximum of 10 trace files will be written at a time.
    /// Parameter: (Int) max total size of trace files
    case traceMaxLogsSize = 32

    /// Sets the 'logGroup' attribute with the specified value for all events in the trace output files.
    ///The default log group is 'default'.
    /// Parameter: (String) value of the logGroup attribute
    case logGroup = 33

    /// Set internal tuning or debugging knobs
    /// Parameter: (String) knob_name=knob_value
    case knob = 40

    /// Set the TLS plugin to load. This option, if used, must be set before any other TLS options
    /// Parameter: (String) file path or linker-resolved name
    case tlsPlugin = 41

    /// Set the certificate chain
    /// Parameter: (Bytes) certificates
    case tlsCertBytes = 42

    /// Set the file from which to load the certificate chain
    /// Parameter: (String) file path
    case tlsCertPath = 43

    /// Set the private key corresponding to your own certificate
    /// Parameter: (Bytes) key
    case tlsKeyBytes = 45

    /// Set the file from which to load the private key corresponding to your own certificate
    /// Parameter: (String) file path
    case tlsKeyPath = 46

    /// Set the peer certificate field verification criteria
    /// Parameter: (Bytes) verification pattern
    case tlsVerifyPeers = 47

    /// Parameter: Option takes no parameter
    case buggifyEnable = 48

    /// Parameter: Option takes no parameter
    case buggifyDisable = 49

    /// Set the probability of a BUGGIFY section being active for the current execution.
    ///Only applies to code paths first traversed AFTER this option is changed.
    /// Parameter: (Int) probability expressed as a percentage between 0 and 100
    case buggifySectionActivatedProbability = 50

    /// Set the probability of an active BUGGIFY section being fired
    /// Parameter: (Int) probability expressed as a percentage between 0 and 100
    case buggifySectionFiredProbability = 51

    /// Disables the multi-version client API and instead uses the local client directly.
    ///Must be set before setting up the network.
    /// Parameter: Option takes no parameter
    case disableMultiVersionClientApi = 60

    /// If set, callbacks from external client libraries can be called from threads created
    /// by the FoundationDB client library. Otherwise, callbacks will be called from either
    /// the thread used to add the callback or the network thread. Setting this option can
    /// improve performance when connected using an external client, but may not be safe to use
    /// in all environments. Must be set before setting up the network.
    /// WARNING: This feature is considered experimental at this time.
    /// Parameter: Option takes no parameter
    case callbacksOn_ExternalThreads = 61

    /// Adds an external client library for use by the multi-version client API.
    /// Must be set before setting up the network.
    /// Parameter: (String) path to client library
    case externalClientLibrary = 62

    /// Searches the specified path for dynamic libraries and adds them to the list of client libraries
    /// for use by the multi-version client API. Must be set before setting up the network.
    /// Parameter: (String) path to directory containing client libraries
    case externalClientDirectory = 63

    /// Prevents connections through the local client, allowing only connections
    /// through externally loaded client libraries. Intended primarily for testing.
    /// Parameter: Option takes no parameter
    case disableLocalClient = 64

    /// Disables logging of client statistics, such as sampled transaction activity.
    /// Parameter: Option takes no parameter
    case disableClientStatisticsLogging = 70

    /// Enables debugging feature to perform slow task profiling.
    /// Requires trace logging to be enabled. WARNING: this feature is not recommended
    /// for use in production.
    // Parameter: Option takes no parameter
    case enableSlowTaskProfiling = 71
}
