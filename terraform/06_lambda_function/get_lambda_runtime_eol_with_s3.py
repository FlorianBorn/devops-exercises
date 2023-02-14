import os
from datetime import datetime, timedelta
from urllib.request import urlopen
import json
import boto3
from botocore.exceptions import ClientError


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


def s3_object_exists(s3_client, bucket_name, status_file_path):
    try:
        s3_client.head_object(Bucket=bucket_name, Key=status_file_path)
    except ClientError as e:
        return int(e.response['Error']['Code']) != 404
    return True
    

def get_runtime_status_from_s3(s3_client, bucket_name, status_file_path):
    file_obj = s3_client.get_object(Bucket=bucket_name, Key=status_file_path)
    file_content = file_obj["Body"].read().decode("utf-8")
    return json.loads(file_content)
    
    
def write_runtime_status_to_s3(s3_client, bucket_name, status_file_path, runtimes):
    from tempfile import NamedTemporaryFile
    
    filename = NamedTemporaryFile(mode="w+b")
    runtimes_json = json.dumps(runtimes)
    with open(filename.name, "w") as fp:
        fp.write(runtimes_json)    
    
    s3_client.upload_file(filename.name, bucket_name, status_file_path)
    

def update_runtime_status(dst_runtimes, src_runtimes):
    updated_product_to_details = dst_runtimes
    
    for src_product, src_all_details in src_runtimes.items():
        dst_product_exist = product_exists(dst_runtimes, src_product)
        
        if not dst_product_exist:
            print(f"Add new product to existing list, product={src_product}")
            updated_product_to_details[src_product] = src_all_details
            continue
        
        for src_details in src_all_details:
            src_cycle = src_details["cycle"]
            dst_product_cycle_exist = product_cycle_exists(dst_runtimes, src_product, src_cycle)

            if dst_product_exist and dst_product_cycle_exist:
                print("nothing to do")
                continue
            elif dst_product_exist and not dst_product_cycle_exist:
                print(f"Add new cycle to existing product, product={src_product}, cycle={src_cycle}")
                tmp_details = updated_product_to_details[src_product]
                updated_product_to_details[product] = tmp_details.append(src_details)

    return updated_product_to_details
    

def lambda_handler(event, context):
    #print('Checking {} at {}...'.format(SITE, event['time']))
    
    s3_client = boto3.client("s3")
    # read eol states from s3 if existing
    status_file_path = "eol_check/foo.txt.txt"
    last_runtime_status = {}
    if s3_object_exists(s3_client, bucket_name="lambda-foobuck", status_file_path=status_file_path):
        last_runtime_status = get_runtime_status_from_s3(s3_client, bucket_name="lambda-foobuck", status_file_path=status_file_path)
    else:
        print("file does not exist!")
        print(last_runtime_status)
    
    print("read status file:")
    print(f"content: {last_runtime_status}")
    
    
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
    distinct_runtimes = set()
    for lambda_function in lambda_functions:
        # get product and its version
        runtime = lambda_function['Runtime']
        distinct_runtimes.add(runtime)
    
    runtimes = {}
    for distinct_runtime in distinct_runtimes:
        tmp_runtime = {}
        product, cycle = get_product_and_cycle_from_runtime(distinct_runtime)
        runtimes[distinct_runtime] = {
            "product": product,
            "cycle": cycle
        }
        
    # get EOL for each runtime
    for distinct_runtime, runtime in runtimes.items():
        cycle_detail = read_product_cycle_eol(runtime["product"], runtime["cycle"])
        eol_status = check_eol(cycle_detail['eol'], warn_days=180, crit_days=90)
        runtime["eol"] = cycle_detail['eol']
        runtime["eol_status"] = eol_status
        runtime["days_to_eol"] = get_days_to_eol(cycle_detail['eol'])
    
    
    # map function_name to runtime
    function_to_runtime = {}
    for lambda_function in lambda_functions:
        function_name = lambda_function["FunctionName"]
        runtime = lambda_function['Runtime']
        function_to_runtime[function_name] = runtimes[runtime]
    
    print("function_to_runtime")
    print(function_to_runtime)
    
    # write EOL status to S3    
    print("write to bucket")
    write_runtime_status_to_s3(s3_client, bucket_name="lambda-foobuck", status_file_path=status_file_path, runtimes=function_to_runtime)
        
    # send notification if neccessary
    for distinct_runtime, runtime in runtimes.items():
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
#        return event['time']
#    finally:
#        print('Check complete at {}'.format(str(datetime.now())))

    
    