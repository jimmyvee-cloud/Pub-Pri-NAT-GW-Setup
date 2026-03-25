# VPC Scripts

Bash scripts for managing AWS VPC networking resources.

---

## Scripts

| Script | Description |
|--------|-------------|
| `create-vpc.sh` | Create a VPC with DNS enabled |
| `create-subnet.sh` | Create a subnet (public or private) |
| `create-igw.sh` | Create and attach an Internet Gateway |
| `create-nat-gw.sh` | Create a NAT Gateway with auto-allocated Elastic IP |
| `create-route-table.sh` | Create a route table |
| `add-route.sh` | Add a route (auto-detects IGW, NAT, peering, VGW, TGW) |
| `associate-route-table.sh` | Associate a route table with a subnet |
| `list-vpcs.sh` | List all VPCs |
| `list-subnets.sh` | List subnets (optionally filter by VPC) |
| `delete-vpc.sh` | Delete a VPC and all its resources (NAT, IGW, subnets, route tables, SGs) |

---

## Build Order

The topology follows this dependency chain:

```
1. VPC
2. Subnets (need VPC)
3. Internet Gateway (needs VPC)
4. NAT Gateway (needs public subnet + auto-creates Elastic IP)
5. Route Tables (need VPC)
   ├── Public:  0.0.0.0/0 → IGW   → associate with public subnet
   └── Private: 0.0.0.0/0 → NAT   → associate with private subnet
6. Security Groups (need VPC)
```

---

## Example: Build a Production VPC

This builds the following topology:

```
VPC (10.0.0.0/16)
├── Public Subnet (10.0.1.0/24)  → IGW  → Internet (in + out)
│   └── NAT Gateway (Elastic IP)
└── Private Subnet (10.0.2.0/24) → NAT  → IGW → Internet (outbound only)
    └── ECS, RDS, ElastiCache
```

### Step 1: Create VPC

```bash
./create-vpc.sh 10.0.0.0/16 prod-vpc
# Output: vpc-0f8dbd8e5a1edc4e9
```

### Step 2: Create Subnets

```bash
# Public subnet (auto-assign public IP)
./create-subnet.sh vpc-xxx 10.0.1.0/24 us-east-1a prod-public-subnet --public
# Output: subnet-00fd55358eb4aed9a

# Private subnet (no public IP)
./create-subnet.sh vpc-xxx 10.0.2.0/24 us-east-1a prod-private-subnet
# Output: subnet-093299ebced9c1b83
```

### Step 3: Create Internet Gateway

```bash
./create-igw.sh vpc-xxx prod-igw
# Output: igw-088f0c2d7bdcb73b8
```

### Step 4: Create NAT Gateway

```bash
# Must be placed in the PUBLIC subnet
./create-nat-gw.sh subnet-pub prod-nat
# Output: nat-026a4dd3e9d1ec1fa (EIP: 100.50.184.100)
# Takes 1-2 minutes to become available
```

### Step 5: Create Route Tables

```bash
# Public route table: 0.0.0.0/0 → IGW
./create-route-table.sh vpc-xxx prod-public-rt
./add-route.sh rtb-pub 0.0.0.0/0 igw-xxx
./associate-route-table.sh rtb-pub subnet-pub

# Private route table: 0.0.0.0/0 → NAT
./create-route-table.sh vpc-xxx prod-private-rt
./add-route.sh rtb-priv 0.0.0.0/0 nat-xxx
./associate-route-table.sh rtb-priv subnet-priv
```

### Step 6: Security Groups

Security groups are created using scripts from `../ec2/`:

```bash
# ECS: default outbound (all traffic)
../ec2/create-security-group.sh prod-ecs-sg "ECS tasks - outbound internet access" vpc-xxx

# RDS: allow PostgreSQL only from ECS security group
../ec2/create-security-group.sh prod-rds-sg "RDS PostgreSQL - access from ECS only" vpc-xxx
aws ec2 authorize-security-group-ingress --group-id sg-rds --protocol tcp --port 5432 --source-group sg-ecs
```

---

## Traffic Flow

### Outbound from private subnet

```
Private EC2/ECS
   ↓
Private Route Table (0.0.0.0/0 → NAT)
   ↓
NAT Gateway (in public subnet)
   ↓
Internet Gateway
   ↓
Internet
```

Return traffic is automatically routed back via NAT (stateful).

### Inbound to public subnet

```
Internet
   ↓
Internet Gateway
   ↓
Public Route Table (0.0.0.0/0 → IGW)
   ↓
EC2/ALB in public subnet (must have public IP + SG allowing traffic)
```

---

## Teardown

Delete everything in one command:

```bash
./delete-vpc.sh vpc-xxx --force
```

This automatically removes (in order):
1. NAT Gateways
2. Internet Gateway
3. Subnets
4. Route tables
5. Security groups (non-default)
6. Orphaned Elastic IPs
7. The VPC itself

---

## Common Mistakes

| Mistake | Why it fails |
|---------|-------------|
| NAT Gateway in private subnet | NAT needs IGW access, so it must be in a public subnet |
| Forgot route table association | Subnet uses the main route table by default (no internet route) |
| No Elastic IP on NAT | NAT Gateway requires an EIP to function |
| Expecting inbound to private subnet | NAT only allows outbound; inbound connections are blocked |
| Overlapping CIDRs with peered VPC | VPC peering requires non-overlapping CIDR ranges |

---

## Cost Notes

| Resource | Cost |
|----------|------|
| VPC, subnets, route tables, IGW | Free |
| NAT Gateway | ~$0.045/hour + $0.045/GB processed (~$32/month idle) |
| Elastic IP (attached) | Free |
| Elastic IP (unattached) | ~$0.005/hour |
| Security Groups | Free |

**Tear down NAT Gateway when not in use to avoid charges.**


