import json
import sys
import random
import time



def lfsr(start, tap_array):
    ''' This function represents a single LFSR.
    The parameters are an initial fill and an
    array of tap indices. The LFSR goes through
    an iteration and returns the next fill.
    The output bit is gotten in the ilfsr()
    function which calls lfsr().
    '''
    temp = start
    for tap in tap_array:
        temp ^= (start >> tap)
    # function is hard coded for deg-32 polys
    temp = (temp & 1) << 31 | (start >> 1)
    start = temp
    # print(start & 1, end='')
    return start



def naive_is_prime(x): # helper function to identify small primes by trial division
    ''' This function is used to build the 
    "filter" that is a part of the prime
    test. It is a naive algorithm that
    does trial division on a number by
    odds up to its square root to find
    primes.
    '''
    x = abs(int(x))
    if x < 2:
        return False
    elif x == 2:
        return True
    elif x % 2 == 0:
        return False
    else:
        for n in range(3, int(x**0.5)+2, 2):
            if x % n == 0:
                return False
        return True



def miller_rabin(n, k): 
    ''' This is an implementation of the widely
    used Miller-Rabin probabilistic primality
    test. Right now the second parameter isn't
    being used. This means we are only running
    MR once on each big number. Fine for our
    purposes but not ideal.
    '''
    if n == 2:
        return True
    l = n - 1  # holds the value of n-1
    m = l
    b = 0
    while m % 2 == 0:
        b += 1
        m >>= 1
    m = int(m)
    a = int(random.randrange(1, l))
    j = 0
    b0 = pow(a, m, n)
    if b0 == 1 or b0 == l:
        #print("n is probably prime: ", n)
        return True
    else:
        b1 = pow(b0, 2, n)
        # print("b1 = ", b1)
        while True:
            j += 1
            if(b1 == 1):
                # print("n is composite")
                return False
            elif(b1 == l):
                #print("n is probably prime: ", n)
                return True
            elif(j > b and b1 != l):
                # print("max iterations reached. n is composite")
                return False
            b1 = pow(b1, 2, n)
            # print("b1 = ", b1)



def prime_test(n, smallPrimes): 
    ''' This is the primality test that 
    combines the filter of dividing
    by small primes and Miller-Rabin.
    '''
    for k in range(len(smallPrimes)):
        if n % smallPrimes[k] == 0:
            # print("n is composite")
            return False
    return miller_rabin(n, 1) # if the input passes the divisibility trials, pass it to miller rabin


def get_small_primes(upper_bound):
    ''' this function returns an array of all
    primes up to specified max. The array is 
    used as a filter when checking for
    primes.
    '''
    t = {}
    t[0] = 2  # manually set 2 as prime
    ctr = 1
    if upper_bound % 2 == 0:  # start odd
        upper_bound += 1
    for x in range (1, upper_bound, 2):  # only check odds
        if naive_is_prime(x):
            t[ctr] = x
            ctr += 1
    return t



def ilfsr(seeds, length):
    ''' This function combines multiple LFSRs.
    seeds is an array of initial fills for
    the multiple registers. length is the 
    desired amount of bits.
    '''
    # the function is hard coded for deg-32 polys
    # to avoid referencing another parameter
    # polys = getPolys(src, 32)
    polys = [[25, 27, 29, 30, 31], [25, 26, 30], [ # array of degree-32 primitive tap polynomials
        25, 26, 27, 28, 30], [24, 27, 30], [24, 26, 27, 28, 31]]
    N = len(polys)
    i = 0
    # output is one bit per lfsr per while loop
    # so the number of loops needed is length / N
    res = ''
    while(i < length / N):
        for k in range(N):
            seeds[k] = lfsr(seeds[k], polys[k])
            res += str(seeds[k] & 1)

        i += 1
    return int(res, 2) # return as a decimal



def gen_random(output_length):
    ''' This function is a pseudorandom number
    generator. The parameter is the desired 
    length in bits of the output. Uses LFSR
    seeded with nanosecond precision time.

    It's possible that this function returns
    a 1025-bit number instead of 1024, but
    that doesn't affect our implementation.
    '''
    fluff = time.time_ns()
    seeds = [(pow(fluff, i) % pow(2, 32)) for i in range(1, 6)]
    random_bits = ilfsr(seeds, output_length - 1) # obtain a random number with (output_length - 1) bits
    base = nbit(output_length) # obtain a number w/ output_length bits from random library
    rand_int = base + random_bits # add the randomization to the non-random base
    return rand_int + 1 if rand_int % 2 == 0 else rand_int # right now the function will return odds only



def nbit(n):  
    ''' This function takes a number of bits
    as input and returns a "random" n-bit
    integer. The built-in random function
    isn't secure, so this shouldn't be 
    the only source of randomness.
    '''
    num = random.randrange((2 ** (n-1)) + 1, (2 ** n) - 1) 
    if num % 2 == 0:
        num += 1
    return num



def get_prime(smallPrimes, bits): 
    ''' This is the function that gets called
    for the key exchange. It combines 3 
    utility functions to return a prime
    with the specified number of bits
    as a string of decimal digits.
    '''
    # find a way to make this accessible so it doesn't have to be recomputed every time
    ## solution: pass it in as a param
    # smallPrimes = getSmallPrimes(1, 2000)
    try:
        t1 = time.perf_counter()
        q = gen_random(bits)
        while prime_test(q, smallPrimes) == False:
            q = gen_random(bits)
        elapsed = time.perf_counter() - t1
        # print(f'[*] {elapsed} sec to generate {len(bin(q))-2}-bit prime')
        return str(q), elapsed
    except Exception as e:
        return e, None


def lambda_handler(event, context):
    data=json.loads((event['body']))
    
    bits=data['bits']
    print(f'bits: {bits}')
    
    # TODO implement
    smallPrimes = get_small_primes(500)
    p, elapsed = get_prime(smallPrimes, (int(bits)))
    return {
        'statusCode': 200,
        'body': json.dumps(f'{p}, {elapsed}'),
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Credentials': 'true',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
            'Access-Control-Max-Age': '86400',  # 24 hours
        }
    }


