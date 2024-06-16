---
date: "2021-10-16"
title: "Database Operations Manual"
summary: "'Database Operations Manual' outlines requirements for operating a database server in production."
tags: ["dba", "work"]
---

Running a database is easy, especially in the cloud, but operating a database is complicated.
This page outlines _operational aspects_ (OA) required to operate a database in production, at scale.

## 1. Security

Security is the first priority: nothing else matters if the database is compromised.
It is better for a database to be offline than hacked.
Security permeates every operational aspects (OA), but these OA address the most critical aspects, like root (super) access and encryption.

### 1.1. Root Access

* Who has access as root / super / with all privileges?
* How is root access controlled?
* From where does root access originate?
* How can root access be reset?

### 1.2. Accounts

* What are each user account, privileges, and purpose?
* From where do user accounts originate?
* What keeps user accounts in sync, updated, correct?
* Does anything audit user accounts?
* Is user account access logged/audited?

### 1.3. Certificates

* Who issues the certificate (certs)?
* How are the certs issued?
* How are (certs) used: connection, user auth, etc.?
* How are the certs updated/rotated?

### 1.4. Encryption

* Who issues the keys?
* How are the keys issued?
* How are the keys used: encryption at rest, database-level encryption, etc.?
* How are the keys updated/rotated?

### 1.5. Compliance and Controls

* Which compliance/regulations (if any) should DBAs be aware of?
* How do compliance/regulations affect operations (“ops”)?
* What controls exists (if any) that affect ops, and how?
* What can we not do/are not allowed to do?

---

## 2. Data Consistency

Data consistency is the second priority: nothing else matters if the data is wrong.
It is better for a database to be offline than to serve bad data.
Moreover, data moves very fast, so data corruption can grow or affect other systems quickly, too.
Prevent at all cost and stop everything if discovered.
The risk is presumed to be inherent to operations and human error, not the database.

### 2.1. Read-only

* How are non-writable instances kept in read-only mode?
* How does the writable instance become read-only and vice versa?
* How do we monitor and alert that only one instance is writable?
* Does read-only prevent the super user from writing?

### 2.2. Verification

* How can data consistency be verified?
* When is data consistency verified?
* How is data inconsistency corrected?

---

## 3. Instance

Instance refers to the low-level database server instance: the running binary providing the port.
In the cloud, many of these OA are not applicable: we pay the cloud provider to handle them.
Otherwise, they are a significant consideration because it’s a lot of work simply to make and maintain a compute instance on which the database server binary can run.

### 3.1. Hardware

* From where does hardware originate?
* How is free hardware found/selected/reserved?
* How is free hardware allocated/provisioned?
* Who is responsible for hardware issues?
* Who is responsible for firmware/BIOS upgrades?
* Is the storage locally-attached or network-attached?
* What are the hardware specs?

### 3.2. Compute

* From where does the base operating system originate?
* Who is responsible for its compatibility with the hardware?
* Who installs it on the hardware?
* Who maintains its lifecycle on the hardware?

### 3.3. Scale

* How does hardware scale up or down?
* Which parts are scalable: CPU, memory, storage, network?
* How long does scaling up/down take?

### 3.4. Roles

* Which instance roles exist, like read replicas, if any?
* In what ways do roles differ from regular instances?
* Which roles can become regular instances, and vice versa?
* Which roles are user-facing or internal?

---

## 4. Lifecycle

Lifecycle refers to the most basic and universal OA for a database instance from provision to decommission.
Sometimes, we provision a database and never hear or think about it again until the engineers decommission it.
That’s possible but unlikely: most databases experience failures and come to our attention for other OA.
But a databases dream of a simple life.

### 4.1. Configure

* Where is the base configuration?
* Can the base configuration be modified?
* How are configuration changes applied?
* Has an expert reviewed the configuration for performance and best practices?

### 4.2. Provision

* How is a database instance (or cluster of instances) provisioned?
* What pre- and post-provision checks, tasks, etc. are necessary?
* How is the final provisioned instance (or cluster) verified?
* How is the provisioned instance (or cluster) added to instance tracking (8.1)?

### 4.3. Upgrade

* How are minor and major version upgrades performed?
* How are upgrades tested before production?
* Is there downtime, or a maintenance window?
* Can upgrades roll back to the previous version?
* What is the upgrade cadence?

### 4.4. Decommission

* How is a database instance (or cluster) decommissioned?
* Is there a final backup?
* How are external pieces (e.g. crypto keys) removed?
* How is instance tracking (8.1) updated?

---

## 5. Availability

Availability refers to everything we do to make the database highly available and reduce downtime when, inevitably, something fails.

### 5.1. Uptime SLA

* What is the uptime SLA?
* How is this measured and reported?
* Does this apply to all instances, or just the writable instance?
* Does this apply to maintenance windows (if any)?

### 5.2. High Availability

* What is the basis (design) of the high availability setup?
* Are all instances (or clusters) highly available?
* Do we optimize for recovery time (RTO) or recovery point (RPO)?
* How many instances can fail (or be offline) before high availability is lost?

### 5.3. Failover

* How do we failover when the writable instance fails?
* How long does failover take?
* What is the typical or expect impact to applications during failover?
* At which network layers does failover operate?
* Does (or when does) failover rely on DNS changes?
* How does replication lag (if any) factor into failover?
* Are failovers automatic (by a service) or manual (by a DBA)?
* How is the standby (new writable) instance chosen?
* Does the standby use separate storage or shared network-attached storage?
* Can we fail back if the original (failed) instance is recovered?

### 5.3. Multi-Region DR

* Is the cluster multi-region?
* How is the active region determined?
* How does everything in 5.3. Failover apply to DR failovers?

### 5.4. Active-Active

* Does the cluster have multiple writable instances?
* How does 5.3. Failover work?
* Can the cluster revert (or degrade) to a single writable instance?
* Are there any quorum or consensus requirements or considerations?

### 5.5. Clone

* When an instance in the cluster fails, how is a new instance cloned to take its place?
* Does cloning rely on/work by restoring the latest backup?
* What order of time (hours, days, etc.) is required to clone a new instance?

---

## 6. Observability

Observability refers to logs, metrics, and everything DBAs and engineers literally see with respect to database health and performance.
Observability determines alerting because, usually, nobody looks at the database until there’s a problem.

### 6.1. Server Metrics

* How are metrics collected from the database server?
* What is the collection resolution (frequency)?
* To where are server metrics reported?
* Are server metrics comprehensive or general?
* What is the retention of server metrics?

### 6.2. Monitoring

* What is the monitoring (graphing and visualization) product?
* Which dashboard, graphs, etc. are authoritative?
* How are the authoritative dashboards, graphs, etc. created and maintained?
* How are server metrics separated by database, cluster, application, etc.?

### 6.3. Alerting

* What are all the alerts?
* Which alerts page the database/application owners?
* Which alerts page the DBAs?
* Which alerts page 24x7 verses business hours?
* How are alerts created and maintained?
* How can application owners customize alerts?

### 6.4. Query Metrics

* How are query metrics collected?
* What is the collection resolution (frequency)?
* To where are server metrics reported?
* What is the retention of query metrics?
* How is query data redacted/anonymized?

### 6.5. Logs

* How and where are server logs (including stdout and stderr) collected?
* How are logs rotated?
* What is the retention of logs?
* Does InfoSec need to scan the logs?
* Is there a specific log for access logging/auditing?

---

## 7. Developer Experience

### 7.1. Management

* How and where do users (engineers) manage their databases?
* How are users authenticated and authorized?
* Which OA can they manage or affect?

### 7.2. App Connection

* How does the application connect to the database?
* What creates and maintains the data source (if any)?
* How does the application authenticate?
* How are application credentials updated/rotated?

### 7.3. Human Connection

* How do humans (users and DBAs) connect to the database?
* How are humans authenticated and authorized?
* What is the mapping of human users to database user accounts?
* How are hunan credentials updated/rotated?
* Can humans connect directly from their laptop/work machine?
* Does the database CLI work as expected (e.g. with pipes and redirects)?

### 7.4. Online Schema Change

* How do users change database schemas, including indexes?
* Can the OSC tool pause and retry (for really long runs)?

---

## 8. Data Infrastructure

### 8.1. Instance Tracking

* How are database instanced tracked?
* Is the tracking system available to all engineers?
* Is the tracking system available to all services?
* Which DBA tools and services depend on the tracking service?

### 8.2. Change Data Capture (CDC)

* How are database changes exposed outside the server?
* Are changes streaming (real-time)?
* Which external services consume the changes?
* How does change stream consumption affect other OA?

### 8.3. Cross-app Access

* Do other applications access the database?
* Does cross-app access ues special roles or other mechanisms?
* How does cross-app access affect other OA?

---

## 9. Backup and Restore

### 9.1. Backup

* How do backups work?
* When do backups run?
* Are backups encrypted when made?
* Are backups used for cloning (5.5)?

### 9.2. Storage and Retention

* Where are backups created and/or stored?
* Do backups move/transition to other places (e.g. S3)?
* Are backups encrypted differently when/where stored?
* What is the backup retention policy?
* How is retention managed?
* Does retention vary by application?
* Can users change the retention?

### 9.3. Restore

* How are backups restored?
* Who can restore backups?
* Which encryption keys are needed to restore a backup?
* How long does restoring a backup generally take?
* Is restoring tested regularly?
* Does compliance (1.5) require periodic restoring?

---

## 10. Cost

Cost refers to money: database aren’t free. They’re quite expensive, actually.

* From which budget does the database cost subtract?
* How are database costs approved?
* How are database costs calculated and reported?
