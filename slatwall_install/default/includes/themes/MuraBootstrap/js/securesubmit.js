jQuery( function() {	
	jQuery('.securesubmit-submit-button').bind('click', secureSubmitFormHandler);
});
function secureSubmitFormHandler() {
	//alert('0');
		if ( jQuery( 'input.providerToken' ).val() == '' ) {
		    alert('1');
			var card 	= jQuery('.securesubmit-card-number').val();
			var cvc 	= jQuery('.securesubmit-card-cvc').val();
			var month	= jQuery('.securesubmit-card-expiry-month').val();
			var year	= '20' + jQuery('.securesubmit-card-expiry-year').val();
			hps.tokenize({
				data: {
					public_key: securesubmit_public_key,
					number: card,
					cvc: cvc,
					exp_month: month,
					exp_year: year
				},
				success: function(response) {
					secureSubmitResponseHandler(response);
				},
				error: function(response) {
					secureSubmitResponseHandler(response);
				}
			});
			return false;
		}
		//else {
		//alert('bad');
		//}

	return true;
}

function secureSubmitResponseHandler( response ) {
    if ( response.message ) {
    	alert(response.message);
        $form.unblock();
    } else {
    	//alert ('[' + response.token_value + ']');
		jQuery('.providerToken').val(response.token_value);
		jQuery('.securesubmit-submit-button').unbind('click');
		jQuery('.securesubmit-submit-button').click();
    }
}

function secureSubmitResponseHandler1( response ) {
    var $form = jQuery("form.securesubmit-payment-form");
    //alert('2');
    if ( response.message ) {
    	alert(response.message);
        $form.unblock();
    } else {
    	//alert ('[' + response.token_value + ']');
        $form.append("<input type='hidden' class='securesubmitToken' name='securesubmitToken' value='" + response.token_value + "'/>");
        $form.submit();
    }
}