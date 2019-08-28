//
//  Persistence.swift
//  Application
//
//  Created by Denis Bystruev on 23/08/2019.
//

import Foundation
import SwiftKueryORM
import SwiftKueryPostgreSQL

class Persistence {
    static func setUp() {
        let pool = PostgreSQLConnection.createPool(
            host: "postgresql-database",
            port: 5432,
            options: [
                .databaseName("tododb"),
                .userName("postgres"),
                .password(ProcessInfo.processInfo.environment["DBPASSWORD"] ?? "nil"),
            ],
            poolOptions: ConnectionPoolOptions(initialCapacity: 10, maxCapacity: 50)
        )
        Database.default = Database(pool)
    }
}
