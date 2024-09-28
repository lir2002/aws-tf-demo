# A sample of IaC in AWS Cloud with Terraform
The configuration code tries to implement the infrastructure that consists of follow components:
1. An Application Load Balancer facing internet users and forwording requests to web servers
    - Redirect HTTP request to HTTPS listener
    - Forward HTTPS request to Target group
1. A scaling group of EC2 instance hosting web servers
    - Instances are distributed in 2 Available Zones.
    - Instances allow only ingress from the Load Balancer
    - The web service redirects all 404 error to a fixed page.
1. A RDS cluster
    - Distributed in the 2 Available zones.
    - Allow only connection to the scaling group instances.

## Further in mind
1. Add TLS between web server and RDS
1. Move Scaling group to private group to reduce cost for ip address and internet risk.
1. Implement a CICD strategy to  update web service and Database
