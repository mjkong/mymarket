package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	"github.com/hyperledger/fabric-chaincode-go/shim"
	pb "github.com/hyperledger/fabric-protos-go/peer"
)

type SimpleChaincode struct {
}

type MymarketCategory struct {
	Name string `json:"name"`
	Desc string `json:"desc"`
}

type MymarketProduct struct {
	Name  string `json:"name"`
	Qty   string `json:"qty"`
	Owner string `json:"owner"`
}

type ProductKey struct {
	Key string
	Idx int
}

type PurchaseHistory struct {
	ProductCode   string `json:"productcode"`
	Qty           string `json:"qty"`
	PurchasedDate string `json:"purchaseddate"`
}

// ===================================================================================
// Main
// ===================================================================================
func main() {
	err := shim.Start(new(SimpleChaincode))
	if err != nil {
		fmt.Printf("Error starting Simple chaincode: %s", err)
	}
}

func (t *SimpleChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	return shim.Success(nil)
}

// Invoke - Our entry point for Invocations
// ========================================
func (t *SimpleChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters()

	if function == "registProducts" {
		return t.registProducts(stub, args)
	} else if function == "getProductList" {
		return t.getProductList(stub, args)
	} else if function == "getProduct" {
		return t.getProduct(stub, args)
	} else if function == "transferOwner" {
		return t.transferOwner(stub, args)
	} else if function == "registCategory" {
		return t.registCategory(stub, args)
	} else if function == "getCategories" {
		return t.getCategories(stub, args)
	} else if function == "purchase" {
		return t.purchase(stub, args)
	}

	fmt.Println("invoke did not find func: " + function) //error
	return shim.Error("Received unknown function invocation")
}

func (t *SimpleChaincode) purchase(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	// var isEmptyCategory bool = false
	// args[0] : 구매자: args[1]: 상품 코드, args[2]: 수량
	var buyer = args[0]
	var productCode = args[1]
	var qty = args[2]

	productAsBytes, err := stub.GetState(productCode)
	if err != nil {
		return shim.Error(err.Error())
	}
	product := MymarketProduct{}
	json.Unmarshal(productAsBytes, &product)

	currentQty, _ := strconv.Atoi(product.Qty)
	purchaseQty, _ := strconv.Atoi(qty)

	fmt.Println("currentQty is " + product.Qty + ", pruchaseQty is " + qty)
	if currentQty < purchaseQty {
		return shim.Error("There is no stock currently")
	}

	currentTime := time.Now()
	purchasedDate := currentTime.Format(time.RFC3339)

	product.Qty = strconv.Itoa(currentQty - purchaseQty)
	updatedProductAsBytes, _ := json.Marshal(product)
	stub.PutState(args[1], updatedProductAsBytes)

	fmt.Println(product)

	historyAsBytes, err := stub.GetState(buyer + "_history")
	if err != nil {
		return shim.Error(err.Error())
	}
	history := []PurchaseHistory{}
	json.Unmarshal(historyAsBytes, &history)

	purchaseHistory := PurchaseHistory{ProductCode: productCode, Qty: qty, PurchasedDate: purchasedDate}
	newHistory := append(history, purchaseHistory)
	newHistoryAsBytes, _ := json.Marshal(newHistory)
	stub.PutState(buyer+"_history", newHistoryAsBytes)

	return shim.Success(nil)
}

func (t *SimpleChaincode) registCategory(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	// var isEmptyCategory bool = false

	keyAsBytes, err := stub.GetState("productCategory")
	if err != nil {
		return shim.Error(err.Error())
	}

	category := []MymarketCategory{}
	json.Unmarshal(keyAsBytes, &category)

	var newCategory = MymarketCategory{Name: args[0], Desc: args[1]}
	appendedCategory := append(category, newCategory)

	appendedCategoryAsBytes, _ := json.Marshal(appendedCategory)
	stub.PutState("productCategory", appendedCategoryAsBytes)

	return shim.Success(nil)
}

func (t *SimpleChaincode) getCategories(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	keyAsBytes, err := stub.GetState("productCategory")
	if err != nil {
		return shim.Error(err.Error())
	}

	category := []MymarketCategory{}
	json.Unmarshal(keyAsBytes, &category)

	return shim.Success(keyAsBytes)
}

func (t *SimpleChaincode) registProducts(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	var newProductKey = ProductKey{}
	json.Unmarshal(generateKeyValue(stub, "latestKey"), &newProductKey)

	var product = MymarketProduct{Name: args[0], Qty: args[1], Owner: args[2]}
	productAsBytes, _ := json.Marshal(product)

	newKeyIdx := strconv.Itoa(newProductKey.Idx)
	var newKeyString = newProductKey.Key + newKeyIdx
	fmt.Println("New key is " + newKeyString)
	stub.PutState(newKeyString, productAsBytes)

	newProductKeyAsBytes, _ := json.Marshal(newProductKey)
	stub.PutState("latestKey", newProductKeyAsBytes)

	return shim.Success(nil)
}

func (t *SimpleChaincode) getProduct(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	productAsBytes, _ := stub.GetState(args[0])
	product := MymarketProduct{}
	json.Unmarshal(productAsBytes, &product)

	fmt.Println("Key : " + product.Name + ", Qty : " + product.Qty + " , Owner : " + product.Owner)

	return shim.Success(nil)

}

func (t *SimpleChaincode) getProductList(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	keyAsBytes, _ := stub.GetState("latestKey")
	productKey := ProductKey{}
	json.Unmarshal(keyAsBytes, &productKey)

	idxStr := strconv.Itoa(productKey.Idx + 1)

	var startKey = "PD0"
	var endKey = productKey.Key + idxStr
	fmt.Println(startKey)
	fmt.Println(endKey)

	resultsIterator, err := stub.GetStateByRange(startKey, endKey)
	if err != nil {
		return shim.Error(err.Error())
	}

	defer resultsIterator.Close()

	var idx int = 0

	// buffer is a JSON array containing QueryResults
	var buffer bytes.Buffer
	buffer.WriteString("[")
	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		fmt.Printf("%d", idx)
		idx++
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return shim.Error(err.Error())
		}
		// Add a comma before array members, suppress it for the first array member
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}
		buffer.WriteString("{\"Key\":")
		buffer.WriteString("\"")
		buffer.WriteString(queryResponse.Key)
		buffer.WriteString("\"")

		buffer.WriteString(", \"Record\":")
		// Record is a JSON object, so we write as-is
		buffer.WriteString(string(queryResponse.Value))
		buffer.WriteString("}")
		bArrayMemberAlreadyWritten = true
	}
	buffer.WriteString("]")

	return shim.Success(buffer.Bytes())
}

func (t *SimpleChaincode) transferOwner(stub shim.ChaincodeStubInterface, args []string) pb.Response {

	productAsBytes, _ := stub.GetState(args[0])
	product := MymarketProduct{}
	json.Unmarshal(productAsBytes, &product)

	product.Owner = args[1]

	newProductAsBytes, err := json.Marshal(product)
	if err != nil {
		return shim.Error(err.Error())
	}
	stub.PutState(args[0], newProductAsBytes)

	return shim.Success(nil)
}

func generateKeyValue(stub shim.ChaincodeStubInterface, key string) []byte {

	var isFirst bool = false

	keyValueAsBytes, err := stub.GetState(key)
	if err != nil {
		fmt.Println(err.Error())
	}

	keyValue := ProductKey{}
	json.Unmarshal(keyValueAsBytes, &keyValue)
	var tempIdx string
	tempIdx = strconv.Itoa(keyValue.Idx)
	fmt.Println(keyValue)
	fmt.Println("Key is " + strconv.Itoa(len(keyValue.Key)))
	if len(keyValue.Key) == 0 || keyValue.Key == "" {
		isFirst = true
		keyValue.Key = "PD"
	}

	if !isFirst {
		keyValue.Idx = keyValue.Idx + 1
	}

	fmt.Println("Last ProductKey is " + keyValue.Key + " : " + tempIdx)

	returnValueBytes, _ := json.Marshal(keyValue)

	return returnValueBytes
}
