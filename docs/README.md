# PrimeTime

## Serverless Prime Generator with Lambda, API Gateway, Python, and Terraform

![[Sample]](/docs/example.png)


### Overview

This is a sample serverless application that explores cryptography concepts. It combines custom Python, AWS, and Terraform. 

### Limitations

The algorithm isn't super optimized. It will timeout on 3072-bit primes sometimes.

### Algorithm

Disclaimer: This isn't meant to service any real cryptographic purpose. Just playing around and taking the opportunity to learn through coding and exposure to the concepts. There are numerous limitations with the current implementation from a security perspective. My goal is to refine this gradually by improving the security of it one piece at a time.

The python code uses a Linear Feedback Shift Register (LFSR) to generate a random number of the specified bit length. That number is then passed to the Miller-Rabin probabilistic primality test which is accurate to a high degree of confidence. This process is repeated until Miller-Rabin identifies a number as prime which can then be displayed back to the user.

### Architecture

The JS code in the HTML first calls to an API resource that goes to a Secrets Manager backend. This isn't an exercise in actual security, just playing around with passing data between multiple API resources and a simple frontend.

In this case, the Secrets Manager backend contains the name of the resource that needs to be accessed for the prime number generator backend.

![[Sample]](/docs/arch.png)