import os
from datetime import datetime, timedelta
from urllib.request import urlopen
import json

SITE = os.environ['site']  # URL of the site to check, stored in the site environment variable
EXPECTED = os.environ['expected']  # String expected to be on the page, stored in the expected environment variable


def get_days_to_eol(eol):
    date_now = datetime.now() #.strftime("%Y-%m-%d")
    datetime_eol = datetime.strptime(eol, "%Y-%m-%d")
    days_to_eol = (datetime_eol - date_now).days
    return days_to_eol


def check_eol(eol, warn_days, crit_days):
    CRIT = "CRITICAL"
    WARNING = "WARNING"
    OK = "OK"
    
    days_to_eol = get_days_to_eol(eol)
    
    if days_to_eol =< crit_days:
        status_code = CRIT
    elif days_to_eol =< warn_days:
        status_code = WARNING
    else:
        status_code = OK
    return status_code
    

def get_lambda_functions():
    import boto3
    client = boto3.client("lambda")
    response = client.list_functions()
    print("lambda_response")
    print(response)
    if response["ResponseMetadata"]["HTTPStatusCode"] != 200:
        print("could not read lambda_functions")
        raise
    
    lambda_functions = response["Functions"]
    print(lambda_functions)
    return lambda_functions


def read_product_eols(product):
    try:
        url = f"https://endoflife.date/api/{product}.json"
        with urlopen(url, timeout=10) as response:
            body = response.read()
    except HTTPError as error:
        print(error.status, error.reason)
    except URLError as error:
        print(error.reason)
    except TimeoutError:
        print("Request timed out")        
    response_body = json.loads(body)
    print(f"{response_body}")


    return response_body


def read_product_cycle_eol(product, cycle):
    try:
        url = f"https://endoflife.date/api/{product}/{cycle}.json"
        with urlopen(url, timeout=10) as response:
            body = response.read()
    except HTTPError as error:
        print(error.status, error.reason)
    except URLError as error:
        print(error.reason)
    except TimeoutError:
        print("Request timed out")        
    response_body = json.loads(body)
    print(f"{response_body}")

    return response_body


def get_product_and_cycle_from_runtime(runtime):
    if runtime.startswith("python"):
        product = "python"
        cycle = runtime.strip("python")
    else:
        print(f"unknown runtime, runtime={runtime}")
        raise
    return product, cycle


def send_notification(message):
    print(f"{message}")


def lambda_handler(event, context):
    print('Checking {} at {}...'.format(SITE, event['time']))
    
    # get all lambda functions
    lambda_functions = get_lambda_functions()
    
    # check for unknown runtimes
    unknown_runtimes = []
    for lambda_function in lambda_functions:
        runtime = lambda_function['Runtime']
        try:
            product, cycle = get_product_and_cycle_from_runtime(runtime)
        except:
            unknown_runtimes.append(runtime)
    
    if unknown_runtimes:
        message = f"There are unknown runtimes. Please update EOL-Check!\nUnknown runtimes: {unknown_runtimes}"
        send_notification(message)
    
    
    # get the runtime of each lambda function
    runtimes = []
    for lambda_function in lambda_functions:
        # get product and its version
        runtime = lambda_function['Runtime']
        product, cycle = get_product_and_cycle_from_runtime(runtime)
        runtimes.append({
            "product": product,
            "cycle": cycle
        })
        
    # get EOL for each runtime
    for runtime in runtimes:
        cycle_detail = read_product_cycle_eol(runtime["product"], runtime["cycle"])
        eol_status = check_eol(cycle_detail['eol'], warn_days=180, crit_days=90)
        runtime["eol"] = cycle_detail['eol']
        runtime["eol_status"] = eol_status
        runtime["days_to_eol"] = get_days_to_eol(cycle_detail['eol'])
        
    # send notification if neccessary
    for runtime in runtimes:
        if runtime["eol_status"] != "OK":
            message = f"Found Runtime nearing its End-of-Life.\nAffected runtime: {runtime}"
            send_notification(message)
    
    print("Checked Runtimes, here is the result:")
    print(runtimes)
    
    try:
        response = read_product_eols("python")
    except:
        print('Check failed!')
        raise
    else:
        print('Check passed!')
        return event['time']
#    finally:
#        print('Check complete at {}'.format(str(datetime.now())))

    
    