#!/bin/bash

# TODO: This script assumes the following
# you named the container where your mongod runs 'mongo'
# you changed MONGO_INITDB_DATABASE to 'admin'
# you set MONGO_INITDB_ROOT_USERNAME to 'root'
# you set MONGO_INITDB_ROOT_PASSWORD to 'secret'
# you set the replica set name to 'rs0' (--replSet)
until mongosh --host 172.17.0.1:27017 --eval 'quit(db.runCommand({ ping: 1 }).ok ? 0 : 2)' &>/dev/null; do
  printf '.'
  sleep 1
done

cd /
echo '
try {
    var config = {
        "_id": "rs0", // TODO update this with your replica set name
        "version": 1,
        "members": [
        {
            "_id": 0,
            "host": "172.17.0.1:27017", // TODO rename this host
            "priority": 2
        },
        ]
    };
    rs.initiate(config, { force: true });
    rs.status();
    sleep(5000);
    // creates another user
    admin = db.getSiblingDB("admin");
    admin.createUser(
          {
        user: "root",
        pwd:  "759fec11d5f6455284e2f0502d729923",
        roles: [ { role: "readWrite", db: "gpump_stg" },
             { role: "readWrite", db: "admin" } ,

        ]
          }
    );
} catch(e) {
    rs.status().ok
}
' > /config-replica.js



sleep 10
# TODO update user, password, authenticationDatabase and host accordingly
mongosh -u root -p "759fec11d5f6455284e2f0502d729923" --authenticationDatabase admin --host 172.17.0.1:27017 /config-replica.js

# if the output of the container mongo_setup exited with code 0, everything is probably okay
