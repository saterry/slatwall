/*

    Slatwall - An Open Source eCommerce Platform
    Copyright (C) ten24, LLC
	
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
	
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
	
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
    Linking this program statically or dynamically with other modules is
    making a combined work based on this program.  Thus, the terms and
    conditions of the GNU General Public License cover the whole
    combination.
	
    As a special exception, the copyright holders of this program give you
    permission to combine this program with independent modules and your 
    custom code, regardless of the license terms of these independent
    modules, and to copy and distribute the resulting program under terms 
    of your choice, provided that you follow these specific guidelines: 

	- You also meet the terms and conditions of the license of each 
	  independent module 
	- You must not alter the default display of the Slatwall name or logo from  
	  any part of the application 
	- Your custom code must not alter or create any files inside Slatwall, 
	  except in the following directories:
		/integrationServices/

	You may copy and distribute the modified version of this program that meets 
	the above guidelines as a combined work under the terms of GPL for this program, 
	provided that you include the source code of that other code when and as the 
	GNU GPL requires distribution of source code.
    
    If you modify this program, you may extend this exception to your version 
    of the program, but you are not obligated to do so.

Notes:

*/

component accessors="true" output="true" displayname="SecureSubmit" implements="Slatwall.integrationServices.PaymentInterface" extends="Slatwall.integrationServices.BasePayment" {
	
	//Global variables

	public any function init(){
		return this;
	}
	
	public string function getPaymentMethodTypes() {
		return "creditCard";
	}
	
	public any function processCreditCard(required any requestBean){
		var responseBean = new Slatwall.model.transient.payment.CreditCardTransactionResponseBean();

		var requestData = {};
		var responseData = {};
		
		var createTokenRequest = new http();
		createTokenRequest.setMethod("post");
		createTokenRequest.setCharset("utf-8");

	    createTokenRequest.addParam(type="header", name="SOAPAction", value="");
	    createTokenRequest.addParam(type="header", name="accept-encoding", value="no-compression");

		//Handle different transaction types
		if (setting("transactionType") == "authorizeAndCharge")
		{
		     populateCreditSaleRequestParamsWithCardInfo(requestBean, createTokenRequest);
		}
		else
		{
               populateCreditAuthRequestParamsWithCardInfo(requestBean, createTokenRequest);
		}
		
		httpResponse = createTokenRequest.send().getPrefix();
	
           var txSuccess = false;

	        if (find( "200", httpResponse.statusCode ))
           {

               responseData = xmlParse( httpResponse.fileContent );
               //Handle different transaction types

            if (setting("transactionType") == "authorizeAndCharge")
            {
	            responseNode = xmlSearch(
	            responseData,
	            "//*[ local-name() = 'CreditSale' ]"
	            );
            }
            else
            {
                responseNode = xmlSearch(
                responseData,
                "//*[ local-name() = 'CreditAuth' ]"
                );
            }

               var responseMessage = "";
               //responseNode won't exist if it wasn't found
            if (isDefined("responseNode") && ArrayLen(responseNode) gt 0) { 

               if (find("00", responseNode[ 1 ].RspCode.xmlText )) {
   	               txSuccess = true;
               }
               responseMessage = responseNode[ 1 ].RspText.xmlText;
            }
            else {
               responseMessage = "ERROR";
            }
		}

           var response = {
               statusCode = httpResponse.statusCode,
               success = txSuccess,
			message = responseMessage
           };
		//Handle the results...
		if (response.success)
		{
   			responseBean.addMessage(messageName="securesubmit.refnbr", message="#responseNode[ 1 ].RefNbr.xmlText#");
		}
		else
		{
		//Error occured- handle it
			handleResponseErrors(responseBean, response);
		}
		
		return responseBean;
	}
	
	private void function populateCreditSaleRequestParamsWithCardInfo(required any requestBean, required any httpRequest)
	{
        // determine which authentication keys to use based on test mode setting
        var activeSecretKey = setting("testSecretKey");
        if (!setting("testMode"))
        {
            activeSecretKey = setting("liveSecretKey");
        }

        var url = "";
        if (findnocase('_uat_', activeSecretKey) != 0)
            url = "https://posgateway.uat.secureexchange.net/Hps.Exchange.PosGateway/PosGatewayService.asmx?wsdl";
        else if (findnocase('_cert_', activeSecretKey) != 0)
            url = "https://posgateway.cert.secureexchange.net/Hps.Exchange.PosGateway/PosGatewayService.asmx?wsdl";
        else
            url = "https://posgateway.secureexchange.net/Hps.Exchange.PosGateway/PosGatewayService.asmx?wsdl";
        
        httpRequest.setUrl(url);

        XMLRequest  = '<?xml version="1.0" encoding="utf-8"?> ';
        XMLRequest  &= '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:hps="http://Hps.Exchange.PosGateway"> ';
        XMLRequest  &= '<soapenv:Header/> ';
        XMLRequest  &= '<soapenv:Body> ';
        XMLRequest  &= '<hps:PosRequest> ';
        XMLRequest  &= ' <hps:Ver1.0> ';
        XMLRequest  &= '    <hps:Header> ';
        XMLRequest  &= '       <hps:DeveloperID>000000</hps:DeveloperID> ';
        XMLRequest  &= '       <hps:VersionNbr>0000</hps:VersionNbr> ';
        XMLRequest  &= '       <hps:SecretAPIKey>' & activeSecretKey & '</hps:SecretAPIKey> ';
        XMLRequest  &= '    </hps:Header> ';
        XMLRequest  &= '    <hps:Transaction> ';
        XMLRequest  &= '       <hps:CreditSale> ';
        XMLRequest  &= '          <hps:Block1> ';
        XMLRequest  &= '             <hps:CardData> ';
        XMLRequest  &= '                <hps:TokenData> ';
        XMLRequest  &= '                   <hps:TokenValue>' & requestBean.getproviderToken() & '</hps:TokenValue> ';
        XMLRequest  &= '                   <hps:ExpMonth>' & requestBean.getExpirationMonth() & '</hps:ExpMonth> ';
        XMLRequest  &= '                   <hps:ExpYear>20' & requestBean.getExpirationYear() & '</hps:ExpYear> ';
        XMLRequest  &= '                </hps:TokenData> ';
        XMLRequest  &= '                <hps:TokenRequest>N</hps:TokenRequest> ';
        XMLRequest  &= '             </hps:CardData> ';
        XMLRequest  &= '             <hps:Amt>' & requestBean.getTransactionAmount() & '</hps:Amt> ';
        XMLRequest  &= '             <hps:CardHolderData> ';
        XMLRequest  &= '                <hps:CardHolderFirstName>' & requestBean.getAccountFirstName() & '</hps:CardHolderFirstName> ';
        XMLRequest  &= '                <hps:CardHolderLastName>' & requestBean.getAccountLastName() & '</hps:CardHolderLastName> ';
        XMLRequest  &= '                <hps:CardHolderAddr>' & requestBean.getBillingStreetAddress() & '</hps:CardHolderAddr> ';
        XMLRequest  &= '                <hps:CardHolderCity>' & requestBean.getBillingCity() & '</hps:CardHolderCity> ';
        XMLRequest  &= '                <hps:CardHolderState>' & requestBean.getBillingStateCode() & '</hps:CardHolderState> ';
        XMLRequest  &= '                <hps:CardHolderZip>' & requestBean.getBillingPostalCode() & '</hps:CardHolderZip> ';
        XMLRequest  &= '                <hps:CardHolderPhone>' & requestBean.getAccountPrimaryPhoneNumber() & '</hps:CardHolderPhone> ';
        XMLRequest  &= '                <hps:CardHolderEmail>' & requestBean.getAccountPrimaryEmailAddress() & '</hps:CardHolderEmail> ';
        XMLRequest  &= '             </hps:CardHolderData> ';
        XMLRequest  &= '             <hps:AllowDup>Y</hps:AllowDup> ';
        XMLRequest  &= '             <hps:AllowPartialAuth>Y</hps:AllowPartialAuth> ';
        XMLRequest  &= '          </hps:Block1> ';
        XMLRequest  &= '       </hps:CreditSale> ';
        XMLRequest  &= '    </hps:Transaction> ';
        XMLRequest  &= ' </hps:Ver1.0> ';
        XMLRequest  &= '</hps:PosRequest> ';
        XMLRequest  &= '</soapenv:Body> ';
        XMLRequest  &= '</soapenv:Envelope> ';
        
        httpRequest.addParam(type="xml", value="#trim( XMLRequest )#");

	}
	

    private void function populateCreditAuthRequestParamsWithCardInfo(required any requestBean, required any httpRequest)
    {

        // determine which authentication keys to use based on test mode setting
        var activeSecretKey = setting("testSecretKey");
        if (!setting("testMode"))
        {
            activeSecretKey = setting("liveSecretKey");
        }

        var url = "";
        if (findnocase('_uat_', activeSecretKey) != 0)
            url = "https://posgateway.uat.secureexchange.net/Hps.Exchange.PosGateway/PosGatewayService.asmx?wsdl";
        else if (findnocase('_cert_', activeSecretKey) != 0)
            url = "https://posgateway.cert.secureexchange.net/Hps.Exchange.PosGateway/PosGatewayService.asmx?wsdl";
        else
            url = "https://posgateway.secureexchange.net/Hps.Exchange.PosGateway/PosGatewayService.asmx?wsdl";
        
        httpRequest.setUrl(url);
        XMLRequest  = '<?xml version="1.0" encoding="utf-8"?> ';
        XMLRequest  &= '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:hps="http://Hps.Exchange.PosGateway"> ';
        XMLRequest  &= '<soapenv:Header/> ';
        XMLRequest  &= '<soapenv:Body> ';
        XMLRequest  &= '<hps:PosRequest> ';
        XMLRequest  &= ' <hps:Ver1.0> ';
        XMLRequest  &= '    <hps:Header> ';
        XMLRequest  &= '       <hps:DeveloperID>000000</hps:DeveloperID> ';
        XMLRequest  &= '       <hps:VersionNbr>0000</hps:VersionNbr> ';
        XMLRequest  &= '       <hps:SecretAPIKey>' & activeSecretKey & '</hps:SecretAPIKey> ';
        XMLRequest  &= '    </hps:Header> ';
        XMLRequest  &= '    <hps:Transaction> ';
        XMLRequest  &= '       <hps:CreditAuth> ';
        XMLRequest  &= '          <hps:Block1> ';
        XMLRequest  &= '             <hps:CardData> ';
        XMLRequest  &= '                <hps:TokenData> ';
        XMLRequest  &= '                   <hps:TokenValue>' & requestBean.getProviderToken() & '</hps:TokenValue> ';
        XMLRequest  &= '                   <hps:ExpMonth>' & requestBean.getExpirationMonth() & '</hps:ExpMonth> ';
        XMLRequest  &= '                   <hps:ExpYear>20' & requestBean.getExpirationYear() & '</hps:ExpYear> ';
        XMLRequest  &= '                </hps:TokenData> ';
        XMLRequest  &= '                <hps:TokenRequest>Y</hps:TokenRequest> ';
        XMLRequest  &= '             </hps:CardData> ';
        XMLRequest  &= '             <hps:Amt>' & requestBean.getTransactionAmount() & '</hps:Amt> ';
        XMLRequest  &= '             <hps:CardHolderData> ';
        XMLRequest  &= '                <hps:CardHolderFirstName>' & requestBean.getAccountFirstName() & '</hps:CardHolderFirstName> ';
        XMLRequest  &= '                <hps:CardHolderLastName>' & requestBean.getAccountLastName() & '</hps:CardHolderLastName> ';
        XMLRequest  &= '                <hps:CardHolderAddr>' & requestBean.getBillingStreetAddress() & '</hps:CardHolderAddr> ';
        XMLRequest  &= '                <hps:CardHolderCity>' & requestBean.getBillingCity() & '</hps:CardHolderCity> ';
        XMLRequest  &= '                <hps:CardHolderState>' & requestBean.getBillingStateCode() & '</hps:CardHolderState> ';
        XMLRequest  &= '                <hps:CardHolderZip>' & requestBean.getBillingPostalCode() & '</hps:CardHolderZip> ';
        XMLRequest  &= '                <hps:CardHolderPhone>' & requestBean.getAccountPrimaryPhoneNumber() & '</hps:CardHolderPhone> ';
        XMLRequest  &= '                <hps:CardHolderEmail>' & requestBean.getAccountPrimaryEmailAddress() & '</hps:CardHolderEmail> ';
        XMLRequest  &= '             </hps:CardHolderData> ';
        XMLRequest  &= '             <hps:AllowDup>Y</hps:AllowDup> ';
        XMLRequest  &= '             <hps:AllowPartialAuth>Y</hps:AllowPartialAuth> ';
        XMLRequest  &= '          </hps:Block1> ';
        XMLRequest  &= '       </hps:CreditAuth> ';
        XMLRequest  &= '    </hps:Transaction> ';
        XMLRequest  &= ' </hps:Ver1.0> ';
        XMLRequest  &= '</hps:PosRequest> ';
        XMLRequest  &= '</soapenv:Body> ';
        XMLRequest  &= '</soapenv:Envelope> ';
        
        httpRequest.addParam(type="xml", value="#trim( XMLRequest )#");

    }


	private string function generateDescription(required any requestBean)
	{
		return "Created by Slatwall. AccountID: #requestBean.getAccountID()#, OrderID: #requestBean.getOrderID()#, OrderPaymentID: #requestBean.getOrderPaymentID()#, TransactionID: #requestBean.getTransactionID()#, Account Name: #requestBean.getAccountFirstName()# #requestBean.getAccountLastName()#, Primary Phone: #requestBean.getAccountPrimaryPhoneNumber()#, Primary Email #requestBean.getAccountPrimaryEmailAddress()#, Billing Name: #requestBean.getBillingName()#";
	}
	
	private void function handleResponseErrors(required any responseBean, required any response) 
	{
		// display error and store error details
        if (!isNull(response.message))
        {
        responseBean.addError(errorName="securesubmit.error", errorMessage="#response.message#");
        responseBean.addMessage(messageName="securesubmit.error.message", message="#response.message#");
        }

	}
	
}