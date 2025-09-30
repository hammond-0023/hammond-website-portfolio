**Project Overview**

A secure, high-performance static website hosted on AWS infrastructure, combining Amazon S3 for content storage, Route 53 for DNS management, CloudFront for content delivery, and GitHub Actions for automated deployment. The implementation uses Infrastructure as Code (IaC) with Terraform for consistent deployment and management.

**Architeture Diagram**

<img width="1197" height="560" alt="image" src="https://github.com/user-attachments/assets/502135ba-0250-419f-af7e-63d4f66a5750" />

**Architecture Components**

- Static Content Storage
- Amazon S3 bucket configured for static website hosting
- Publicly accessible content storage
- Automatically scalable storage solution


**Content Delivery Network**

- CloudFront distribution for global content delivery
- Edge locations for reduced latency
- Automatic content caching
- Integrated with S3 origin

**Security Layer**

- ACM SSL/TLS certificates for HTTPS support
- Automatic certificate renewal
- Secure communication between clients and edge locations

**DNS Management**
*
- Route 53 hosted zone for domain management
- A-record alias configuration for root domain
- Automatic regional routing for optimal performance

**Infrastructure Management**

- Terraform configuration for consistent deployment
- Version-controlled infrastructure code
- Automated resource provisioning
- Automated Deployment

**GitHub Actions CI/CD pipeline**

- Automated deployment on code changes
- CloudFront cache invalidation
- Version-controlled deployment process

