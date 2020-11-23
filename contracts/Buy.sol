pragma solidity > 0.6.0;
contract Buy {
    

      function buyInsurance(address _productAddr, uint _amount, uint _blocks, 
                address payable [] calldata _ipAddrs, uint[] calldata _ipAmount) 
            external payable whenNotPaused returns (bytes32 _orderId) 
    {
        require(_ipAddrs.length <= 3, "_ipAddrs.length is too long..");
        require(_ipAddrs.length == _ipAmount.length, "_ipAddrs and _ipAmount need to correspond");

        Product storage _productInfo = _products[_productAddr];
        require(_productInfo.status == 1, "this product is disabled!");

        // Initialize order data
        _orderId        = _buildOrderId(_productAddr, _amount, _blocks);

        uint premium    = _calculatePremium(_amount, _blocks, _productInfo.feeRate);
        require(premium == msg.value, "premium and msg.value is not the same");

        Order storage _order = insuranceOrders[_orderId];
        require(_order.buyer == address(0), "order id is not empty?!");

        _order.buyer    = _msgSender();
        _order.premium  = premium;
        _order.price    = _amount;
        _order.state    = 0;
        _order.settleBlockNumber = _blocks.add(block.number);

        _doBuyInsurance(_order, _productInfo, _ipAddrs, _ipAmount);

        emit NewOrder(_orderId, _order.buyer, _productAddr, _order.premium, _order.price, _order.settleBlockNumber);
    }

    function _doBuyInsurance(Order storage _order, Product storage _productInfo, 
                             address payable [] memory _ipAddrs, uint[] memory _ipAmount)
        internal returns (bool) 
    { 
        uint _totalAmount       = 0;
        uint _totalIpPremium    = 0;
        for (uint8 i = 0; i < _ipAddrs.length; i++) {
            require(_ipAmount[i] > 0, "_ipAmount is zero");

            InsuranceProvider storage _currProvider = ethPool.ips[_ipAddrs[i]];
            require(_currProvider.avail >= _ipAmount[i], "Insurance provider avail balance not enough");

            uint ipPremium = _updateBuyInsuranceIP(_currProvider, _ipAddrs[i], _ipAmount[i], _order.price, _order.premium);
            
            _totalIpPremium = _totalIpPremium.add(ipPremium);
            _totalAmount = _totalAmount.add(_ipAmount[i]);

            // Set order details
            _order.orderDetails[i] = OrderDetail(_ipAddrs[i], _ipAmount[i]);
            _order.totalProviders = _order.totalProviders + 1;
        }

        require(_totalAmount == _order.price, "The calldata amount is inconsistent with the order amount");
        //分配保费
        _distributeOtherPremium(_order.premium, _totalIpPremium);

        // Update pool avail and locked
        ethPool.avail = ethPool.avail.sub(_totalAmount);
        ethPool.locked = ethPool.locked.add(_totalAmount);

        // Update product totalPremium and totalSale
        _productInfo.totalPremium = _productInfo.totalPremium.add(_order.premium);
        _productInfo.totalSale = _productInfo.totalSale.add(_totalAmount);

        // should be premium to do mine param, because some one can let amount bigger, and blocks less
        getMine().takerMining(_order.premium, _msgSender());

        return true;
    }
    
}