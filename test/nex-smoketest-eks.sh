#!/bin/bash

# DIR="${BASH_SOURCE%/*}"
# if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
# . "$DIR/nex-include.sh"

# to ensure if 1 command fails.. build fail
set -e

# ensure prefix is pass in
if [ $# -lt 1 ] ; then
	echo "NEX smoketest needs prefix"
	echo "nex-smoketest.sh acceptance"
	exit
fi

PREFIX=$1

# check if doing local smoke test
if [ "${PREFIX}" != "local" ]; then
    echo "Production Performance Test in CF"
    STD_APP_URL=${PREFIX}
else
    echo "Local Performance Test"
    STD_APP_URL=http://localhost:8000
fi

echo STD_APP_URL=${STD_APP_URL}

# Test: Create Products
echo "=== Creating a product id: the_odyssey ==="
curl -k -XPOST  "${STD_APP_URL}/products" \
	 -d '{"id": "the_odyssey", "title": "The Odyssey", "passenger_capacity": 101, "maximum_speed": 5, "in_stock": 10}'
echo
# Test: Get Product
echo "=== Getting product id: the_odyssey ==="
curl -sk "${STD_APP_URL}/products/the_odyssey" | jq .

# Test: Create Order
echo "=== Creating Order ==="
ORDER_ID=$(curl -sk -XPOST -d '{"order_details": [{"product_id": "the_odyssey", "price": "100000.99", "quantity": 1}]}' "${STD_APP_URL}/orders")
echo ${ORDER_ID}
ID=$(echo ${ORDER_ID} | jq '.id')

# Test: Get Order back
echo "=== Getting Order ==="
curl -sk "${STD_APP_URL}/orders/${ID}" | jq -r