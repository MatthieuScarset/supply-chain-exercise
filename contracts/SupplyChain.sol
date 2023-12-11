// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {

  // <owner>
  address public owner;

  // <skuCount> (default: 0)
  // @see https://docs.soliditylang.org/en/v0.8.23/control-structures.html#default-value
  int public skuCount;

  // <items mapping>
  mapping(int => Item) public items;

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
    int sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }

  /*
   * Events
   */

  event LogForSale(int sku);
  event LogSold(int sku);
  event LogShipped(int sku);
  event LogReceived(int sku);

  /*
   * Modifiers
   */

  modifier isOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier isSeller(int _sku) {
    require (msg.sender == items[_sku].seller);
    _;
  }

  modifier isBuyer(int _sku) {
    require (msg.sender == items[_sku].buyer);
    _;
  }

  modifier paidEnough(uint _price) {
    require(msg.value >= _price);
    _;
  }

  modifier refundExtraValue(int _sku) {
    _;
    //refund them after logic.
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
  }

  /**
   * State modifiers
   */
  modifier itemIsForSale(int _sku) {
    // Make sure item exists because uninitialized item's state is 0 too.
    require (items[_sku].sku > 0, "Item does not exist");
    require (items[_sku].state == State.ForSale, "Item is not for sale");
    _;
  }

  modifier itemIsSold(int _sku) {
    require (items[_sku].state == State.Sold, "Item is not sold");
    _;
  }

  modifier itemIsShipped(int _sku) {
    require (items[_sku].state == State.Shipped, "Item is not shipped");
    _;
  }

  modifier itemIsReceived(int _sku) {
    require (items[_sku].state == State.Received, "Item is not received");
    _;
  }

  constructor() public {
    owner = msg.sender;
    skuCount = 1;
  }

  function addItem(string memory _name, uint _price) public returns (bool) {
    items[skuCount] = Item({
      name: _name,
      sku: skuCount,
      price: _price,
      state: State.ForSale,
      seller: msg.sender,
      buyer: address(0)
    });
    skuCount = skuCount + 1;
    emit LogForSale(skuCount);
    return true;
  }

  function buyItem(int _sku)
    public
    payable
    itemIsForSale(_sku)
    paidEnough(msg.value)
    refundExtraValue(_sku)
    returns (bool)
  {
    Item storage item = items[_sku];
    item.seller.transfer(item.price);
    item.buyer = msg.sender;
    item.state = State.Sold;
    emit LogSold(_sku);
    return true;
  }

  function shipItem(int _sku)
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

  function receiveItem(int _sku)
    public
    itemIsShipped(_sku) isBuyer(_sku)
    isBuyer(_sku)
    returns (bool)
  {
    Item storage item = items[_sku];
    item.state = State.Received;
    emit LogReceived(_sku);
    return true;
  }

  function fetchItem(int _sku)
    public
    view
    returns (string memory name, int sku, uint price, uint state, address seller, address buyer)
  {
    Item storage item = items[_sku];
    return (
      item.name,
      item.sku,
      item.price,
      uint(item.state),
      seller,
      buyer
    );
  }
}
