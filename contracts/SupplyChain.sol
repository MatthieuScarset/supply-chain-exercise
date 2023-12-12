// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {

  // <owner>
  address public owner;

  // <skuCount> (default: 0)
  // @see https://docs.soliditylang.org/en/v0.8.23/control-structures.html#default-value
  uint public skuCount;

  // <items mapping>
  mapping(uint => Item) public items;

  // <enum State: ForSale, Sold, Shipped, Received>
  enum State {
    ForSale,
    Sold,
    Shipped,
    Received
  }

  // <struct Item: name, sku, price, state, seller, and buyer>
  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }

  /*
   * Events
   */

  event LogForSale(uint sku);
  event LogSold(uint sku);
  event LogShipped(uint sku);
  event LogReceived(uint sku);

  /*
   * Modifiers
   */

  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier isSeller(uint _sku) {
    require (msg.sender == items[_sku].seller);
    _;
  }

  modifier isBuyer(uint _sku) {
    require (msg.sender == items[_sku].buyer);
    _;
  }

  modifier paidEnough(uint _price) {
    require(msg.value >= _price);
    _;
  }

  modifier refundExtraValue(uint _sku) {
    _;
    //refund them after logic.
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
  }

  /**
   * State modifiers
   */
  modifier itemIsForSale(uint _sku) {
    // Make sure item exists because uninitialized item's state is 0 too.
    require (items[_sku].seller != address(0), "Item does not exist");
    require (items[_sku].state == State.ForSale, "Item is not for sale");
    _;
  }

  modifier itemIsSold(uint _sku) {
    require (items[_sku].state == State.Sold, "Item is not sold");
    _;
  }

  modifier itemIsShipped(uint _sku) {
    require (items[_sku].state == State.Shipped, "Item is not shipped");
    _;
  }

  modifier itemIsReceived(uint _sku) {
    require (items[_sku].state == State.Received, "Item is not received");
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  function addItem(string memory _name, uint _price) public returns (bool) {
    items[skuCount] = Item({
      name: _name,
      sku: skuCount,
      price: _price,
      state: State.ForSale,
      seller: payable(address(msg.sender)),
      buyer: payable(address(0))
    });
    skuCount = skuCount + 1;
    emit LogForSale(skuCount);
    return true;
  }

  function buyItem(uint _sku)
    public
    payable
    itemIsForSale(_sku)
    paidEnough(items[_sku].price)
    refundExtraValue(_sku)
    returns (bool)
  {
    Item storage item = items[_sku];
    item.seller.transfer(item.price);
    item.buyer = payable(address(msg.sender));
    item.state = State.Sold;
    emit LogSold(_sku);
    return true;
  }

  function shipItem(uint _sku)
    public
    itemIsSold(_sku)
    isSeller(_sku)
    returns (bool)
  {
    Item storage item = items[_sku];
    item.state = State.Shipped;
    emit LogShipped(_sku);
    return true;
  }

  function receiveItem(uint _sku)
    public
    itemIsShipped(_sku)
    isBuyer(_sku)
    returns (bool)
  {
    Item storage item = items[_sku];
    item.state = State.Received;
    emit LogReceived(_sku);
    return true;
  }

  function fetchItem(uint _sku)
    public
    view
    returns (string memory name, uint sku, uint price, uint state, address seller, address buyer)
  {
    Item memory item = items[_sku];
    return (
      item.name,
      item.sku,
      item.price,
      uint(item.state),
      item.seller,
      item.buyer
    );
  }
}
