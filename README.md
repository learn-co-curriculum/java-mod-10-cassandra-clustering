# Cassandra Clustering

## Learning Goals

- Hands on experience building a local Dev Cassandra cluster

## Instructions

We are now going to implement a Cassandra cluster utilizing several local Docker containers. As Cassandra is designed predominately with large-scale
clusters in mind, all the following concepts and procedures should be more simplistic and straightforward than what we worked though in the Postgres
cluster lab. Keep an eye on the infrastructure requirements as we go through this demo, and try to conceptualize where complexity changes might occur
for a production application's environment.


## Building a Local Development Cassandra Cluster

Let's get started again with the cluster network, and a single Cassandra node


``` text
docker run --name cassandra-node-1 --network labnetwork -d -p 9042:9042 \
    -e CASSANDRA_CFG_ENV_MAX_HEAP_SIZE="2048M" \
    -e CASSANDRA_CFG_ENV_HEAP_NEWSIZE="512M" \
    bitnami/cassandra:4.0.5-debian-11-r1
```

Now load the demo data into this new Database.
The Cassandra instances in this lab may take some time to fully start, so just retry a few times if you get a failure.

``` text
docker cp words.csv cassandra-node-1:/
docker cp words.cql cassandra-node-1:/
docker exec -it cassandra-node-1 cqlsh -u cassandra -p cassandra -f /words.cql
```

At this point, we can take a quick look at the state of this single node cluster.

``` text
docker exec -it cassandra-node-1 /bin/bash
I have no name!@208104c57e58:/$ nodetool status
```
``` shell
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load       Tokens  Owns (effective)  Host ID                               Rack 
UN  172.20.0.2  73.46 KiB  256     100.0%            24fe47c5-ff97-4971-8ed9-4797289b49c7  rack1
```

And we can run some simple queries against this data

``` text
docker exec -it cassandra-node-1 /bin/bash
I have no name!@208104c57e58:/$ cqlsh -u cassandra -p cassandra
```
``` shell
Connected to My Cluster at 127.0.0.1:9042
[cqlsh 6.0.0 | Cassandra 4.0.5 | CQL spec 3.4.5 | Native protocol v5]
Use HELP for help.
```
``` text
cassandra@cqlsh> TRACING ON
cassandra@cqlsh> SELECT * FROM cluster_benchmark.words WHERE uuid = 'd908e5e6-9a3c-4b1c-be6f-7e13c8ac8d0e';
```
``` shell
 uuid                                 | b64              | word
--------------------------------------+------------------+-------------
 d908e5e6-9a3c-4b1c-be6f-7e13c8ac8d0e | YWxsZXJnb2xvZ3kK | allergology

(1 rows)

Tracing session: b7bb5190-0c5a-11ed-a76f-5d8512bbd341

 activity                                                                                                                         | timestamp                  | source     | source_elapsed | client
----------------------------------------------------------------------------------------------------------------------------------+----------------------------+------------+----------------+-----------
                                                                                                               Execute CQL3 query | 2022-07-25 20:45:28.745000 | 172.20.0.2 |              0 | 127.0.0.1
 Parsing SELECT * FROM cluster_benchmark.words WHERE uuid = 'd908e5e6-9a3c-4b1c-be6f-7e13c8ac8d0e'; [Native-Transport-Requests-1] | 2022-07-25 20:45:28.745000 | 172.20.0.2 |            349 | 127.0.0.1
                                                                                Preparing statement [Native-Transport-Requests-1] | 2022-07-25 20:45:28.746000 | 172.20.0.2 |            735 | 127.0.0.1
                                                                          Executing single-partition query on words [ReadStage-2] | 2022-07-25 20:45:28.747000 | 172.20.0.2 |           1485 | 127.0.0.1
                                                                                       Acquiring sstable references [ReadStage-2] | 2022-07-25 20:45:28.747000 | 172.20.0.2 |           1673 | 127.0.0.1
                                                                                          Merging memtable contents [ReadStage-2] | 2022-07-25 20:45:28.747000 | 172.20.0.2 |           1778 | 127.0.0.1
                                                                                        Key cache hit for sstable 1 [ReadStage-2] | 2022-07-25 20:45:28.747000 | 172.20.0.2 |           2070 | 127.0.0.1
                                                                             Read 1 live rows and 0 tombstone cells [ReadStage-2] | 2022-07-25 20:45:28.748000 | 172.20.0.2 |           2477 | 127.0.0.1
                                                                                                                 Request complete | 2022-07-25 20:45:28.748029 | 172.20.0.2 |           3029 | 127.0.0.1
```

As we can already see from the single node tracing output, Cassandra is natively handling the routing of this request, and executing it on the only node. Whereas we needed
more complex setups with Postgres to route SQL queries, this is all being done internally to the DB system with Cassandra.

Let us scale up this system, and see how it behaves differently

``` text
docker run --name cassandra-node-2 --network labnetwork -d -p 9043:9043 \
    -e CASSANDRA_CFG_ENV_MAX_HEAP_SIZE="2048M" \
    -e CASSANDRA_CFG_ENV_HEAP_NEWSIZE="512M" \
    -e CASSANDRA_CQL_PORT_NUMBER=9043 \
    -e CASSANDRA_SEEDS=cassandra-node-1 \
    bitnami/cassandra:4.0.5-debian-11-r1
    
docker exec -it cassandra-node-1 /bin/bash
I have no name!@208104c57e58:/$ nodetool status
```
``` shell
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load       Tokens  Owns (effective)  Host ID                               Rack 
UN  172.20.0.3  16.89 MiB  256     52.3%            6bcc4b96-775d-411d-86fb-7406b33cf8d0  rack1
UN  172.20.0.2  16.91 MiB  256     47.7%            24fe47c5-ff97-4971-8ed9-4797289b49c7  rack1
```
``` text
I have no name!@208104c57e58:/$ cqlsh -u cassandra -p cassandra
cassandra@cqlsh> TRACING ON
cassandra@cqlsh> SELECT * FROM cluster_benchmark.words WHERE uuid = 'd908e5e6-9a3c-4b1c-be6f-7e13c8ac8d0e';
```
``` shell
 uuid                                 | b64              | word
--------------------------------------+------------------+-------------
 d908e5e6-9a3c-4b1c-be6f-7e13c8ac8d0e | YWxsZXJnb2xvZ3kK | allergology

(1 rows)

Tracing session: ce340460-12a6-11ed-8a02-c9efe76b2a44

 activity                                                                                                                         | timestamp                  | source     | source_elapsed | client
----------------------------------------------------------------------------------------------------------------------------------+----------------------------+------------+----------------+-----------
                                                                                                               Execute CQL3 query | 2022-08-02 21:05:15.177000 | 172.20.0.2 |              0 | 127.0.0.1
 Parsing SELECT * FROM cluster_benchmark.words WHERE uuid = 'd908e5e6-9a3c-4b1c-be6f-7e13c8ac8d0e'; [Native-Transport-Requests-1] | 2022-08-02 21:05:15.183000 | 172.20.0.2 |           6301 | 127.0.0.1
                                                                                Preparing statement [Native-Transport-Requests-1] | 2022-08-02 21:05:15.184000 | 172.20.0.2 |           7354 | 127.0.0.1
                                                                          Executing single-partition query on roles [ReadStage-2] | 2022-08-02 21:05:15.189000 | 172.20.0.2 |          12579 | 127.0.0.1
                                                                                       Acquiring sstable references [ReadStage-2] | 2022-08-02 21:05:15.189000 | 172.20.0.2 |          12851 | 127.0.0.1
                                          Skipped 0/1 non-slice-intersecting sstables, included 0 due to tombstones [ReadStage-2] | 2022-08-02 21:05:15.190000 | 172.20.0.2 |          13177 | 127.0.0.1
                                                                                        Key cache hit for sstable 1 [ReadStage-2] | 2022-08-02 21:05:15.190000 | 172.20.0.2 |          13493 | 127.0.0.1
                                                                          Merged data from memtables and 1 sstables [ReadStage-2] | 2022-08-02 21:05:15.191000 | 172.20.0.2 |          14501 | 127.0.0.1
                                                                             Read 1 live rows and 0 tombstone cells [ReadStage-2] | 2022-08-02 21:05:15.191000 | 172.20.0.2 |          14768 | 127.0.0.1
                                                                 reading data from /172.20.0.3:7000 [Native-Transport-Requests-1] | 2022-08-02 21:05:15.193000 | 172.20.0.2 |          16395 | 127.0.0.1
                                    Sending READ_REQ message to /172.20.0.3:7000 message size 117 bytes [Messaging-EventLoop-3-4] | 2022-08-02 21:05:15.194000 | 172.20.0.2 |          17278 | 127.0.0.1
                                                        READ_REQ message received from /172.20.0.2:7000 [Messaging-EventLoop-3-6] | 2022-08-02 21:05:15.199000 | 172.20.0.3 |           1062 | 127.0.0.1
                                                                          Executing single-partition query on words [ReadStage-1] | 2022-08-02 21:05:15.205000 | 172.20.0.3 |           7202 | 127.0.0.1
                                                                                       Acquiring sstable references [ReadStage-1] | 2022-08-02 21:05:15.206000 | 172.20.0.3 |           7598 | 127.0.0.1
                                                                                          Merging memtable contents [ReadStage-1] | 2022-08-02 21:05:15.206000 | 172.20.0.3 |           7834 | 127.0.0.1
                                                                 Partition index with 0 entries found for sstable 1 [ReadStage-1] | 2022-08-02 21:05:15.209000 | 172.20.0.3 |          11287 | 127.0.0.1
                                                                             Read 1 live rows and 0 tombstone cells [ReadStage-1] | 2022-08-02 21:05:15.212000 | 172.20.0.3 |          13782 | 127.0.0.1
                                                                             Enqueuing response to /172.20.0.2:7000 [ReadStage-1] | 2022-08-02 21:05:15.212000 | 172.20.0.3 |          14045 | 127.0.0.1
                    Sending READ_RSP message to cassandra-node-1/172.20.0.2:7000 message size 124 bytes [Messaging-EventLoop-3-1] | 2022-08-02 21:05:15.213000 | 172.20.0.3 |          14763 | 127.0.0.1
                                                        READ_RSP message received from /172.20.0.3:7000 [Messaging-EventLoop-3-8] | 2022-08-02 21:05:15.214000 | 172.20.0.2 |          38064 | 127.0.0.1
                                                               Processing response from /172.20.0.3:7000 [RequestResponseStage-3] | 2022-08-02 21:05:15.215000 | 172.20.0.2 |          38385 | 127.0.0.1
                                                                                                                 Request complete | 2022-08-02 21:05:15.216570 | 172.20.0.2 |          39570 | 127.0.0.1
```

We can see much longer tracing now, as all the nodes in the cluster are now needing to interact. Looking at the changes to execution time, you can see some relatively large slowdowns compared to the previous
single node setup. It is interesting to note though that this is the best case scenario, using `uuid` for the search, which have been implemented as a Primary Key.

Try the following to see just how much more expensive queries can run if designed without having Cassandra cluster routing in mind

``` text
docker exec -it cassandra-node-1 /bin/bash
I have no name!@208104c57e58:/$ cqlsh -u cassandra -p cassandra
cassandra@cqlsh> CREATE INDEX ON cluster_benchmark.words (word);
cassandra@cqlsh> TRACING ON
cassandra@cqlsh> SELECT * FROM cluster_benchmark.words WHERE word = 'allergology';
```
``` shell
 uuid                                 | b64              | word
--------------------------------------+------------------+-------------
 d908e5e6-9a3c-4b1c-be6f-7e13c8ac8d0e | YWxsZXJnb2xvZ3kK | allergology

(1 rows)

Tracing session: 9c2481b0-12a7-11ed-8a02-c9efe76b2a44

 activity                                                                                                                              | timestamp                  | source     | source_elapsed | client
---------------------------------------------------------------------------------------------------------------------------------------+----------------------------+------------+----------------+-----------
                                                                                                                    Execute CQL3 query | 2022-08-02 21:11:00.683000 | 172.20.0.2 |              0 | 127.0.0.1
                                                                                                                    ...
                                                                                                                    (lots of operations)
                                                                                                                    ...
                                                                                                                      Request complete | 2022-08-02 21:11:00.792343 | 172.20.0.2 |         109343 | 127.0.0.1
```

## Cluster Keyspace Management


We didn't go into any great depth on the Postgres server side when implementing clustering. It is worth noting though that the tool we specifically used was called Repmgr, and was embedded directly into the
Container image that we used. On its own it is a fairly complex setup, but this process was removed from our implementation as the provided image met our specific use case.

In the case of Cassandra however, all the steps we've taken are everything that is needed for Cassandra to fully manage clustering of any given Keyspace.
Let's take a look at how Cassandra manages this for some live environment changes.

We'll start with retrieving a few records, and inspecting where they reside on the physical layer

``` text
docker exec -it cassandra-node-1 /bin/bash
I have no name!@208104c57e58:/$ cqlsh -u cassandra -p cassandra -e "SELECT * FROM cluster_benchmark.words;" | sort | head
```
``` shell
 0001fd3b-7d8e-43a4-af1d-2f629e72c997 |             Y2hhcnR1bGFzCg== |          chartulas
 000283c8-a4e9-4d15-95fb-d8a51609243e |         Y3J5c3RhbGxvaWQK |      crystalloid
 0002d98a-5c42-4136-9a46-47198bdab92a |             Y2h1Y2tzdG9uZQo= |          chuckstone
 00035505-473e-420d-b798-bbf293424a56 |             YWdncmVnYXRpbmcK |         aggregating
 0003d4d1-612f-401f-b9c4-b208653b8ab3 |             Y29yb2RpZXMK |        corodies
 0005af52-fb24-471c-9451-67bc420cd453 |             YXNrYXJlbAo= |         askarel
 00066854-2967-46aa-8e19-8203e446585e |     ZGVhc3NpbWlsYXRpb24K |    deassimilation
 000811f6-0d80-4454-9c68-79d36402669e |                     ZG9idWxlCg== |                  dobule
```
``` text
I have no name!@208104c57e58:/$ nodetool getendpoints cluster_benchmark words '0001fd3b-7d8e-43a4-af1d-2f629e72c997'
```
``` shell
172.20.0.3
```
``` text
I have no name!@208104c57e58:/$ nodetool getendpoints cluster_benchmark words '000283c8-a4e9-4d15-95fb-d8a51609243e'
```
``` shell
172.20.0.3
```
``` text
I have no name!@208104c57e58:/$ nodetool getendpoints cluster_benchmark words '0002d98a-5c42-4136-9a46-47198bdab92a'
```
``` shell
172.20.0.2
```
``` text
I have no name!@208104c57e58:/$ nodetool getendpoints cluster_benchmark words '00035505-473e-420d-b798-bbf293424a56'
```
``` shell
172.20.0.3
```

Currently, each node holds about half of all records. Depending on which system token any Primary Key gets hashed into, Cassandra will place the entry into that given node. Let's see what happens though when
adding new nodes to a cluster live.

``` text
# A fourth node can be added as well if your workstation can spare the resources. Make sure to change the name and ports used.    
docker run --name cassandra-node-3 --network labnetwork -d -p 9044:9044 \
    -e CASSANDRA_CFG_ENV_MAX_HEAP_SIZE="2048M" \
    -e CASSANDRA_CFG_ENV_HEAP_NEWSIZE="512M" \
    -e CASSANDRA_CQL_PORT_NUMBER=9044 \
    -e CASSANDRA_SEEDS=cassandra-node-1 \
    bitnami/cassandra:4.0.5-debian-11-r1
    
docker exec -it cassandra-node-1 /bin/bash
I have no name!@208104c57e58:/$ nodetool status
```
``` shell
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load       Tokens  Owns (effective)  Host ID                               Rack 
UN  172.20.0.3  6.1 MiB    256     30.9%             6bcc4b96-775d-411d-86fb-7406b33cf8d0  rack1
UN  172.20.0.4  93.36 KiB  256     35.2%             709938d1-37a1-405c-9f96-74808d728159  rack1
UN  172.20.0.2  5.56 MiB   256     34.0%             24fe47c5-ff97-4971-8ed9-4797289b49c7  rack1
```
``` text
I have no name!@208104c57e58:/$ cqlsh -u cassandra -p cassandra -e "SELECT * FROM cluster_benchmark.words;" | sort | head
```
``` shell
 0001fd3b-7d8e-43a4-af1d-2f629e72c997 |         Y2hhcnR1bGFzCg== |       chartulas
 000283c8-a4e9-4d15-95fb-d8a51609243e |         Y3J5c3RhbGxvaWQK |     crystalloid
 0002d98a-5c42-4136-9a46-47198bdab92a |         Y2h1Y2tzdG9uZQo= |      chuckstone
 00035505-473e-420d-b798-bbf293424a56 |             YWdncmVnYXRpbmcK |         aggregating
 0003d4d1-612f-401f-b9c4-b208653b8ab3 |                 Y29yb2RpZXMK |            corodies
 0005af52-fb24-471c-9451-67bc420cd453 |             YXNrYXJlbAo= |           askarel
 00066854-2967-46aa-8e19-8203e446585e |     ZGVhc3NpbWlsYXRpb24K |    deassimilation
 000811f6-0d80-4454-9c68-79d36402669e |                 ZG9idWxlCg== |              dobule
```
``` text
I have no name!@f23acc8dc6db:/$ nodetool getendpoints cluster_benchmark words '0001fd3b-7d8e-43a4-af1d-2f629e72c997'
```
``` shell
172.20.0.4
```
``` text
I have no name!@f23acc8dc6db:/$ nodetool getendpoints cluster_benchmark words '000283c8-a4e9-4d15-95fb-d8a51609243e'
```
``` shell
172.20.0.3
```
``` text
I have no name!@f23acc8dc6db:/$ nodetool getendpoints cluster_benchmark words '0002d98a-5c42-4136-9a46-47198bdab92a'
```
``` shell
172.20.0.2
```
``` text
I have no name!@f23acc8dc6db:/$ nodetool getendpoints cluster_benchmark words '00035505-473e-420d-b798-bbf293424a56'
```
``` shell
172.20.0.4
```

We can see that just adding now nodes has prompted Cassandra to rebalance where the backend data resides. No maintenance is needed on the part of the DB end user to ensure data is available throughout the cluster.
As an end developer, we can however specify a few parameters of interest when creating the Keyspace object. For this lab so far, we have used the following from `words.cql` for the sake of clarity:

``` text
-- Create keyspace
CREATE KEYSPACE IF NOT EXISTS cluster_benchmark WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : '1' };
...
```

Let's see how the cluster reconfigures itself once we update the `replication_factor` to match the amount of nodes available. This is what you would expect from best practices, to ensure high availability of your data.

``` text
docker exec -it cassandra-node-1 /bin/bash
I have no name!@208104c57e58:/$ nodetool status
```
``` shell
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load       Tokens  Owns (effective)  Host ID                               Rack 
UN  172.20.0.3  6.1 MiB    256     30.9%             6bcc4b96-775d-411d-86fb-7406b33cf8d0  rack1
UN  172.20.0.4  93.36 KiB  256     35.2%             709938d1-37a1-405c-9f96-74808d728159  rack1
UN  172.20.0.2  5.56 MiB   256     34.0%             24fe47c5-ff97-4971-8ed9-4797289b49c7  rack1
```
``` text
I have no name!@208104c57e58:/$ cqlsh -u cassandra -p cassandra
cassandra@cqlsh> ALTER KEYSPACE cluster_benchmark WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : '3' }; # or however many nodes you have
```
``` shell
Warnings :
When increasing replication factor you need to run a full (-full) repair to distribute the data.
```
``` text
cassandra@cqlsh>quit
I have no name!@f23acc8dc6db:/$ nodetool repair -full
```
``` shell
...
[2022-08-02 22:02:34,576] Repair completed successfully
```
``` text
I have no name!@f23acc8dc6db:/$ nodetool status
```
``` shell
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load       Tokens  Owns (effective)  Host ID                               Rack 
UN  172.20.0.3  20.82 MiB  256     100.0%            6bcc4b96-775d-411d-86fb-7406b33cf8d0  rack1
UN  172.20.0.4  21.24 MiB  256     100.0%            709938d1-37a1-405c-9f96-74808d728159  rack1
UN  172.20.0.2  19.22 MiB  256     100.0%            24fe47c5-ff97-4971-8ed9-4797289b49c7  rack1
```
``` text
I have no name!@208104c57e58:/$ cqlsh -u cassandra -p cassandra -e "SELECT * FROM cluster_benchmark.words;" | sort | head
```
``` shell
 0001fd3b-7d8e-43a4-af1d-2f629e72c997 |         Y2hhcnR1bGFzCg== |       chartulas
 000283c8-a4e9-4d15-95fb-d8a51609243e |         Y3J5c3RhbGxvaWQK |     crystalloid
 0002d98a-5c42-4136-9a46-47198bdab92a |         Y2h1Y2tzdG9uZQo= |      chuckstone
 00035505-473e-420d-b798-bbf293424a56 |             YWdncmVnYXRpbmcK |         aggregating
 0003d4d1-612f-401f-b9c4-b208653b8ab3 |                 Y29yb2RpZXMK |            corodies
 0005af52-fb24-471c-9451-67bc420cd453 |             YXNrYXJlbAo= |           askarel
 00066854-2967-46aa-8e19-8203e446585e |     ZGVhc3NpbWlsYXRpb24K |    deassimilation
 000811f6-0d80-4454-9c68-79d36402669e |                 ZG9idWxlCg== |              dobule
```
``` text
I have no name!@f23acc8dc6db:/$ nodetool getendpoints cluster_benchmark words '0001fd3b-7d8e-43a4-af1d-2f629e72c997'
```
``` shell
172.20.0.4
172.20.0.2
172.20.0.3
```
``` text
I have no name!@f23acc8dc6db:/$ nodetool getendpoints cluster_benchmark words '000283c8-a4e9-4d15-95fb-d8a51609243e'
```
``` shell
172.20.0.3
172.20.0.4
172.20.0.2
```
``` text
I have no name!@f23acc8dc6db:/$ nodetool getendpoints cluster_benchmark words '0002d98a-5c42-4136-9a46-47198bdab92a'
```
``` shell
172.20.0.2
172.20.0.3
172.20.0.4
```
``` text
I have no name!@f23acc8dc6db:/$ nodetool getendpoints cluster_benchmark words '00035505-473e-420d-b798-bbf293424a56'
```
``` shell
172.20.0.4
172.20.0.2
172.20.0.3
```

We can see now that all the entries get transparently(mostly) balanced across all nodes. The `getendpoints` command now shows the primary node, followed by all replicas.
This usecase supports both high availability and potentially greater compute performance for reads, but could have a storage size tradeoff for very large data sets, or
write performance concerns depending on how consistency is tuned(more on this in a later lab).


## Client Side Cluster Balancing

In the case of Spring Boot, we are actually using a Cassandra driver that handles the cluster state management and load balancing automatically for us. If you take a
look at the properties we set in the previous lab, and read through the [common properties docs](https://docs.spring.io/spring-boot/docs/current/reference/html/application-properties.html#application-properties.data.spring.data.cassandra.contact-points),
you'll see only two parameters for initializing the networking between the client and cluster: `contact-points` and `local-datacenter`
The driver uses IPs listed in `contact-points` to bootstrap itself into the cluster, but then pulls and manages a list of all other systems by itself. And it uses `local-datacenter`
to select a subset of cluster nodes based on logical separations of the cluster. E.g. think dedicated cluster nodes per geographical region.

No additional work is needed on the side of the application developers to modify client side parameters to work with scaling clusters.

Let's take a look at some application trace logs to see this in action. We can reuse the Spring application from the previous lab, but will need to make a few system property changes into `RestServiceApplication.java`:

``` java
...
public static void main(String[] args) {
        System.setProperty("datastax-java-driver.advanced.request-tracker.class", "RequestLogger");
        System.setProperty("datastax-java-driver.advanced.request-tracker.logs.success.enabled", "true");
        SpringApplication.run(RestServiceApplication.class, args);
    }
```

We'll create the Keyspace again in this new cluster

``` text
cassandra@cqlsh> CREATE KEYSPACE IF NOT EXISTS spring_cassandra WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : '3' };
```

After running the application, and hitting the endpoint a few times, we'll see the following in the application logs:

``` shell
...
2022-07-26 11:17:29.986  INFO 25858 --- [        s0-io-4] c.d.o.d.i.core.tracker.RequestLogger     : [s0|2125077447][Node(endPoint=/127.0.0.1:9042, hostId=39545500-f19a-40ac-b80d-fba8af4ea9f0, hashCode=b5e76e7)] Success (2 ms) [1 values] SELECT * FROM counter WHERE name=? LIMIT 1 [name='spring_counter']
2022-07-26 11:17:29.990  INFO 25858 --- [        s0-io-4] c.d.o.d.i.core.tracker.RequestLogger     : [s0|125527134][Node(endPoint=/127.0.0.1:9042, hostId=39545500-f19a-40ac-b80d-fba8af4ea9f0, hashCode=b5e76e7)] Success (1 ms) [2 values] INSERT INTO counter (count,name) VALUES (?,?) [count=7, name='spring_counter']
2022-07-26 11:17:31.176  INFO 25858 --- [        s0-io-3] c.d.o.d.i.core.tracker.RequestLogger     : [s0|215569931][Node(endPoint=/172.20.0.3:9043, hostId=13c935d9-19c9-4241-99eb-ae023ae30ff3, hashCode=486cdc30)] Success (9 ms) [1 values] SELECT * FROM counter WHERE name=? LIMIT 1 [name='spring_counter']
2022-07-26 11:17:31.190  INFO 25858 --- [        s0-io-3] c.d.o.d.i.core.tracker.RequestLogger     : [s0|63903237][Node(endPoint=/172.20.0.4:9044, hostId=65ade06d-0a53-481b-a6c9-f7a49d3254c6, hashCode=623517a1)] Success (3 ms) [2 values] INSERT INTO counter (count,name) VALUES (?,?) [count=8, name='spring_counter']
2022-07-26 11:17:32.471  INFO 25858 --- [        s0-io-4] c.d.o.d.i.core.tracker.RequestLogger     : [s0|2102695963][Node(endPoint=/127.0.0.1:9042, hostId=39545500-f19a-40ac-b80d-fba8af4ea9f0, hashCode=b5e76e7)] Success (2 ms) [1 values] SELECT * FROM counter WHERE name=? LIMIT 1 [name='spring_counter']
2022-07-26 11:17:32.479  INFO 25858 --- [        s0-io-3] c.d.o.d.i.core.tracker.RequestLogger     : [s0|1370394074][Node(endPoint=/172.20.0.3:9043, hostId=13c935d9-19c9-4241-99eb-ae023ae30ff3, hashCode=486cdc30)] Success (4 ms) [2 values] INSERT INTO counter (count,name) VALUES (?,?) [count=9, name='spring_counter']
2022-07-26 11:17:33.578  INFO 25858 --- [        s0-io-4] c.d.o.d.i.core.tracker.RequestLogger     : [s0|697338953][Node(endPoint=/127.0.0.1:9042, hostId=39545500-f19a-40ac-b80d-fba8af4ea9f0, hashCode=b5e76e7)] Success (1 ms) [1 values] SELECT * FROM counter WHERE name=? LIMIT 1 [name='spring_counter']
2022-07-26 11:17:33.584  INFO 25858 --- [        s0-io-3] c.d.o.d.i.core.tracker.RequestLogger     : [s0|74223942][Node(endPoint=/172.20.0.3:9043, hostId=13c935d9-19c9-4241-99eb-ae023ae30ff3, hashCode=486cdc30)] Success (2 ms) [2 values] INSERT INTO counter (count,name) VALUES (?,?) [count=10, name='spring_counter']
```

We can see that the listed endPoint's are being balanced across all nodes in our cluster.

Go ahead and see the behavior of this system as you stop and restart individual Docker containers. See which environment changes the application can accommodate, and which ones end up causing failure.


## Testing

The following commands will run the tests to validate that this environment was setup correctly. A screenshot of the successful tests can be uploaded as a submission.

``` text
docker run --network labnetwork -it --rm -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd)/test:/test inspec-lab exec docker.rb
```
``` shell
Profile:   tests from docker.rb (tests from docker.rb)
Version:   (not specified)
Target:    local://
Target ID: 

  ✔  Cassandra Node 1 Running: Cassandra Docker instance 1 is running
     ✔  #<Inspec::Resources::DockerImageFilter:0x00005638c8538d90> with repository == "bitnami/cassandra" tag == "4.0.5-debian-11-r1" is expected to exist
     ✔  #<Inspec::Resources::DockerContainerFilter:0x00005638c6999940> with names == "cassandra-node-1" image == "bitnami/cassandra:4.0.5-debian-11-r1" status is expected to match [/Up/]
     ✔  Cassandra query: SELECT cluster_name FROM system.local output is expected to match /My Cluster/
  ✔  Cassandra Node 2 Running: Cassandra Docker instance 2 is running
     ✔  #<Inspec::Resources::DockerContainerFilter:0x00005638c6e19b50> with names == "cassandra-node-2" image == "bitnami/cassandra:4.0.5-debian-11-r1" status is expected to match [/Up/]
     ✔  Cassandra query: SELECT cluster_name FROM system.local output is expected to match /My Cluster/
  ✔  Cassandra Node 3 Running: Cassandra Docker instance 3 is running
     ✔  #<Inspec::Resources::DockerContainerFilter:0x00005638c53896a0> with names == "cassandra-node-3" image == "bitnami/cassandra:4.0.5-debian-11-r1" status is expected to match [/Up/]
     ✔  Cassandra query: SELECT cluster_name FROM system.local output is expected to match /My Cluster/
  ✔  Cassandra Benchmark Keyspace: Benchmark Keyspace exists
     ✔  Cassandra query: DESCRIBE KEYSPACE cluster_benchmark output is expected not to match /not found/
  ✔  Cassandra Benchmark Table: Words Table  exists
     ✔  Cassandra query: SELECT uuid FROM cluster_benchmark.words output is expected to match /d908e5e6-9a3c-4b1c-be6f-7e13c8ac8d0e/
  ✔  Cassandra Benchmark Keyspace Replication: Benchmark Keyspace Replication 3+
     ✔  Cassandra query: DESCRIBE KEYSPACE cluster_benchmark output is expected to match /'replication_factor': '3'/ or match /'replication_factor': '4'/
  ✔  Spring Cassandra Keyspace: Spring Keyspace exists
     ✔  Cassandra query: DESCRIBE KEYSPACE spring_cassandra output is expected not to match /not found/
  ✔  Spring Cassandra Keyspace Replication: Spring Keyspace Replication 3+
     ✔  Cassandra query: DESCRIBE KEYSPACE spring_cassandra output is expected to match /'replication_factor': '3'/ or match /'replication_factor': '4'/


Profile Summary: 8 successful controls, 0 control failures, 0 controls skipped
Test Summary: 12 successful, 0 failures, 0 skipped
```
``` text
docker run --network labnetwork -it --rm -v /var/run/docker.sock:/var/run/docker.sock -v $(pwd)/test:/test inspec-lab exec cassandra.rb -t docker://cassandra-node-1
```
``` shell
Profile:   tests from cassandra.rb (tests from cassandra.rb)
Version:   (not specified)
Target:    docker://f23acc8dc6db162b5d466415d575849e55a166ca18a71e9440148f38d9eaf404
Target ID: da39a3ee-5e6b-5b0d-b255-bfef95601890

  ✔  Cassandra Cluster: Cassandra Cluster Up and Ready
     ✔  Command: `nodetool status | grep UN | wc -l` stdout is expected to match "3" or match "4"


Profile Summary: 1 successful control, 0 control failures, 0 controls skipped
Test Summary: 1 successful, 0 failures, 0 skipped
```
