import os
from datetime import datetime, timedelta
from urllib.request import urlopen
import json
import boto3


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
    
    if days_to_eol <= crit_days:
        status_code = CRIT
    elif days_to_eol <= warn_days:
        status_code = WARNING
    else:
        status_code = OK
    return status_code
    

def get_lambda_functions():
    import boto3
    client = boto3.client("lambda")
    response = client.list_functions()
    if response["ResponseMetadata"]["HTTPStatusCode"] != 200:
        print("could not read lambda_functions")
        raise
    
    lambda_functions = response["Functions"]
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

    return response_body


def get_product_and_cycle_from_runtime(runtime):
    if runtime.startswith("python"):
        product = "python"
        cycle = runtime.strip("python")
    else:
        print(f"unknown runtime, runtime={runtime}")
        raise
    return product, cycle


def send_email(message):
    # Set up the SES client
    ses = boto3.client('ses')

    # Construct the message
    message = {
        'Subject': {
            'Data': 'Test email'
        },
        'Body': {
            'Text': {
                'Data': 'This is a test email'
            }
        }
    }

    # Send the message
    response = ses.send_email(
        Source='your_email_address@example.com',
        Destination={
            'ToAddresses': [
                'charismatischunwiderstehlicherrabe@mdz.email',
            ]
        },
        Message=message
    )

    print(response)
    

def send_notification(message):
    print(f"{message}")




def lambda_handler(event, context):
    #print('Checking {} at {}...'.format(SITE, event['time']))
    
    send_email("foobar")
    # get all lambda functions
    print("Get all lambda functions...")
    lambda_functions = get_lambda_functions()
    
    # check for unknown runtimes
    print("Check, if there are unknown runtimes...")
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
    print("Get distinct runtimes from all lambda functions...")
    distinct_runtimes = set()
    for lambda_function in lambda_functions:
        # get product and its version
        runtime = lambda_function['Runtime']
        distinct_runtimes.add(runtime)    
        
    # get the runtime of each lambda function
    print("Initiate new runtime object...")
    runtimes = {}
    for distinct_runtime in distinct_runtimes:
        tmp_runtime = {}
        product, cycle = get_product_and_cycle_from_runtime(distinct_runtime)
        runtimes[distinct_runtime] = {
            "product": product,
            "cycle": cycle
        }       
        
    # get EOL for each runtime
    print("Get the End Of Life (EOL) info for each runtime...")
    for distinct_runtime, runtime in runtimes.items():
        cycle_detail = read_product_cycle_eol(runtime["product"], runtime["cycle"])
        eol_status = check_eol(cycle_detail['eol'], warn_days=180, crit_days=90)
        runtime["eol"] = cycle_detail['eol']
        runtime["eol_status"] = eol_status
        runtime["days_to_eol"] = get_days_to_eol(cycle_detail['eol'])
        
    # map function_name to runtime
    print("Mapping functions to runtimes...")
    function_to_runtime = {}
    for lambda_function in lambda_functions:
        function_name = lambda_function["FunctionName"]
        runtime = lambda_function['Runtime']
        function_to_runtime[function_name] = runtimes[runtime]        
        
    # send notification if neccessary
    for function, runtime in function_to_runtime.items():
        if runtime["eol_status"] != "OK":
            message = f"Found Lambda Function which uses Runtime with near End-of-Life runtime.\nFunction: {function}\nAffected runtime: {runtime}"
            send_notification(message)
    
    print("function_to_runtime")
    print(function_to_runtime)
    
    
    
    try:
        response = read_product_eols("python")
    except:
        print('Check failed!')
        raise
    else:
        print('Check passed!')
#        return event['time']
#    finally:
#        print('Check complete at {}'.format(str(datetime.now())))

    
    