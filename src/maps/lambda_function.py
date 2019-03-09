# Final Project: Adventure Game with Microservices
# Date: 26-Nov-2018
# Authors: A01377162 Guillermo Pérez Trueba
#          A01020507 Luis Ángel Lucatero Villanueva
#          A01375996 Alan Joseph Salazar Romero

import yaml
import json
import boto3
import decimal

general_yalm = 0
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('maps')

# Function to encode a json with decimal types
def json_encode_decimal(obj):
    if isinstance(obj, decimal.Decimal):
        return str(obj)
    raise TypeError(repr(obj) + " is not JSON serializable")

# FUnction to create a response from a status code and a body
def create_response(status_code, body):
    return {
        'statusCode': status_code,
        'body': json.dumps(body, indent=2),
        'headers': {
            'Content-Type': 'application/json'
        }
    }

# Function to convert position number to the corresponding string
def pos_to_string(pos):
    maker = {
        0: "north",
        1: "south",
        2: "east",
        3: "west",
        4: "up",
        5: "down",
        6: "contents"
    }
    return maker.get(pos, "Undefined")
    
def create_map(_id, yaml):
    response = table.put_item(
        Item={
            'id': _id,
            'yml': yaml
        }
    )
    
def get_map(_id):
    try:
        response = table.get_item(
            Key={
                'id': _id
            }
        )
    except CError as e:
        print(e.response['Error']['Message'])
    else:
        return response['Item']['yaml']
        
def update_map(_id, yaml):
    response = table.update_item(
        Key={
            'id': _id
        },
        UpdateExpression="set yaml = :y",
        ExpressionAttributeValues={
            ':y': yaml
        },
        ReturnValues="UPDATED_NEW"
    )
    

# Function for getting a position from the xaml
def formatting(myyaml, _id, pos):
    _id = int(_id)
    pos = pos_to_string(int(pos))
    respond_dictionary = 0
    counter = 0
    data = 0
    for x in myyaml:
        if counter == _id:
            data = x
        counter += 1

    for y in data:
        if y == pos:
            respond_dictionary = {
                y: data[y]
            }
            return json.dumps(respond_dictionary, default=json_encode_decimal)  

# Function for getting and setting a position on the xaml
def formatting2(myyaml, id, pos, new_val):
    pos = pos_to_string(pos)
    respond_dictionary = 0
    counter = 0
    for x in myyaml:
        if counter == id:
            for y in x:
                if y == pos:
                    x[y] = new_val
                    respond_dictionary = {
                        "ok": "operation was success"
                    }
                    general_yalm = myyaml 
                    return json.dumps(respond_dictionary)
        counter += 1
        
# Function for getting the element on a position
def getElement(_id, pos):
    general_yalm = get_map(0)
    possible = formatting(general_yalm, _id, pos)
    return possible

# Function for setting the element on a position
def setElement(_id, pos, new_one):
    possible = 0
    general_yalm = get_map(0)
    possible = formatting2(general_yalm, _id, pos, new_one)
    update_map(0, general_yalm)
    return possible

# Function for setting basic castle 
def resetMap():
    with open("mapzero.yml", 'r') as stream:
        try:
            general_yalm = yaml.load(stream)
            update_map(0, general_yalm)
        except yaml.YAMLError as exc:
            print(exc)
    respond_dictionary = {
        "ok": "operation was success"
    }
    return json.dumps( respond_dictionary)

# Function that handles the lambda function of the AWS lambda service
def lambda_handler(event, context):
    method = event.get('httpMethod', '')
    
    if method == 'GET':
        params = event.get('queryStringParameters')
        _id = params.get('id')
        pos = params.get('pos')
        return create_response(200, getElement(_id, pos))
    elif method == 'POST':
        body = json.loads(event.get('body', ''))
        type = body.get('type', '') #RESET or UPDATE
        if type == 'UPDATE':
            _id = body.get('id', '')
            if _id:
                pos = body.get('pos', '')
                new_one = body.get('new_one', '')
                return setElement(_id, pos, new_one)
        elif type == 'RESET':
            return resetMap()

#method for initializing 
if __name__ == '__main__':
   app.run(port = 8083)
