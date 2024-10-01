// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract Houses{
    address admin = msg.sender;
    // Параметры объекта
    struct Realty{
        address owner;
        bool isDeposit;
        uint area;
        bool isLive;
        uint timeOfLife;
        bool isGift;
        bool isSale;
        uint timeOfLastSale;
    }
    // Параметры Продажи
    struct Sale{
        uint id ;
        uint price;
        uint timeOfSale;
        uint timeDiff;
        address buyer;
    }
    // Параметры Дарения
    struct Gift {
        uint id;
        address newOwner;
        uint timeDiff;
    }
    // Параметры залога
    struct Deposit{
        uint id;
        uint priceDeposit;
        address pledger;
        uint timeOfDeposit;
        uint timeConfirm;
    }
    Realty[] private  realties;
    Sale[] private saleArray;
    Gift[] private giftArray;
    Deposit[] private depositArray;
    // Проверка на Админа
   modifier onlyAdmin{
    require(msg.sender == admin , unicode"Вы не администратор");
         _;
   }
    // Проверка на собственника
    modifier onlyOwner(uint _i) {
        require(msg.sender ==realties[_i].owner, unicode"Вы не являетесь собственником недвижимости");
        _;
    }
    // Проверка на залогодателя
    modifier onlyPledger(uint _i) {
    require(msg.sender == depositArray[_i].pledger, unicode"Вы не залогодатель");
    _;
    }
    // Проверка недвижимости
    modifier propertyCheckOnDepositGiftSale(uint _id) {
        require(!realties[_id].isDeposit,unicode"Недвижимость заложена");
        require(!realties[_id].isGift, unicode"Недвижимость в процессе дарения");
        require(!realties[_id].isSale, unicode"Недвижимость уже продаётся");
        _;
    }
    // Создание объекта недвижимости
    function createObjects (bool _isDeposit, uint _area, bool _isLive) external onlyAdmin{
        realties.push(Realty(msg.sender, _isDeposit, _area, _isLive,0,false,false,block.timestamp));
    }
    function createSale (uint _id, uint _price, uint _timeOfSale) external onlyOwner(_id) propertyCheckOnDepositGiftSale(_id) {
        saleArray.push(Sale(_id, _price, _timeOfSale,block.timestamp - realties[_id].timeOfLastSale,address(0))); 
        
    }
    // Перевод средств
    function transferSale (uint _id) external payable  {
        require(msg.value >= saleArray[_id].price , unicode"Недостаточно средств");
        require(saleArray[_id].buyer == address(0), unicode"Покупатель  уже найден"); 
        require(saleArray[_id].timeOfSale > block.timestamp, unicode"Предложение не актуально");
        require(realties[saleArray[_id].id].owner != msg.sender, unicode"Невозможно купить недвижимость у себя");
        saleArray[_id].buyer = msg.sender;
    }
    // Принятие средств
    function confirmSale(uint _id) external  onlyOwner(saleArray[_id].id) {
        require(saleArray[_id].timeOfSale > block.timestamp , unicode"Предложение не актуально");
        require(saleArray[_id].buyer != address(0), unicode"Покупатель ещё не найден"); 
        payable (msg.sender).transfer(saleArray[_id].price); 
        realties[saleArray[_id].id].owner = saleArray[_id].buyer;
        saleArray[_id].timeOfSale = block.timestamp;
        saleArray[_id].buyer = address(0);
        realties[saleArray[_id].id].timeOfLife += saleArray[_id].timeDiff;
        realties[saleArray[_id].id].timeOfLastSale = block.timestamp;
    }
    // Отмена продажи
    function cancelSale (uint _id) external onlyOwner(saleArray[_id].id) {
        require(saleArray[_id].timeOfSale > block.timestamp, unicode"Предложение неактуально");
        saleArray[_id].timeOfSale = block.timestamp;        
    }
    // Возврат средств в случае окончания срока продажи 
    function returnMoney (uint _id) external onlyAdmin {
        require(saleArray[_id].timeOfSale <= block.timestamp, unicode"Срок продажи не истёк");
        require(saleArray[_id].buyer != address(0),unicode"Средства уже переданы");
        payable (saleArray[_id].buyer).transfer(saleArray[_id].price);
        saleArray[_id].buyer = address(0);
    }
    // Дарение
    function createGift(uint _id, address _newOwner) external  onlyOwner(giftArray[_id].id) propertyCheckOnDepositGiftSale(_id) {
        require(_newOwner != address(0));
        giftArray.push(Gift(_id,_newOwner,block.timestamp - realties[_id].timeOfLastSale ));
    }
    // Подтверждение
    function confirmGift(uint _id) external{
        require(msg.sender == giftArray[_id].newOwner,unicode"Вы не являетесь новым собственником");
        uint realtyId= giftArray[_id].id;
        realties[realtyId].owner = msg.sender;
        giftArray[_id].newOwner = address(0);
        realties[realtyId].timeOfLastSale = block.timestamp;
        realties[realtyId].timeOfLife += giftArray[_id].timeDiff;
    }
    // Отмена предложения о дарении
    function canselGift (uint _id) external {
        require(giftArray[_id].newOwner !=address(0), unicode"Дарение уже выполнено");
        giftArray[_id].newOwner = address(0);
    } 
    // Создание предложения о залоге
    function createDeposit (uint _id,uint _price, uint _timeOfDeposit) external onlyOwner(depositArray[_id].id) propertyCheckOnDepositGiftSale(_id) {
        require(_price > 0 , unicode"Предложение не актуально");
        depositArray.push(Deposit(_id,_price, address(0),_timeOfDeposit, 0));
       
    }
    // Перевод средств
    function deposit (uint _id) external payable {
        require(depositArray[_id].pledger ==address(0), unicode"Недвижимость уже заложена" );   
        require(depositArray[_id].pledger != realties[depositArray[_id].id].owner, unicode"Вы не можете быть залогодадетелем у своей недвижимости");
        require(msg.value >= depositArray[_id].priceDeposit, unicode"Недостаточно средств" );
        require(depositArray[_id].priceDeposit > 0 , unicode"Предложение не актуально");
        depositArray[_id].pledger = msg.sender;
    }
    // Принятие средств
    function confirmDeposit(uint _id) external   onlyOwner(depositArray[_id].id){
        require(depositArray[_id].pledger != address(0), unicode"Средства приняты");
        require(depositArray[_id].priceDeposit > 0 , unicode"Предложение не актуально");
        payable (msg.sender).transfer(depositArray[_id].priceDeposit);
        depositArray[_id].timeConfirm = block.timestamp;
    }
    // Переход недвижимости залогодателю
    function transitionPledger (uint _id) external onlyPledger(_id){
        require(depositArray[_id].pledger != address(0), unicode"Средства приняты");
        require(block.timestamp > depositArray[_id].timeConfirm + depositArray[_id].timeOfDeposit, unicode"Предложение не актуально");   
        realties[depositArray[_id].id].owner = depositArray[_id].pledger;
        depositArray[_id].timeOfDeposit = block.timestamp;
        depositArray[_id].pledger = address(0);
    }
    // Отмена заявки пока не было принятия средств
    function canselDeposit(uint _id) external onlyOwner(depositArray[_id].id){
        require(depositArray[_id].timeConfirm == 0, unicode"Средства переведены собственнику");
        require(depositArray[_id].priceDeposit > 0 , unicode"Предложение не актуально");
        depositArray[_id].priceDeposit = 0;
    }
    // Возврат средств в случае отсутствия подтверждения средств
    function returnDeposit (uint _id) external onlyPledger(_id){
        require(depositArray[_id].timeConfirm == 0, unicode"Средства переведены собственнику");
        payable (msg.sender).transfer(depositArray[_id].priceDeposit);
        depositArray[_id].pledger = address(0);  
    }
    // Оплата залога
    function payDeposit (uint _id) external payable onlyOwner(depositArray[_id].id){
        require(depositArray[_id].timeConfirm + depositArray[_id].timeOfDeposit > block.timestamp , unicode"Предложение не актуально");
        require(depositArray[_id].pledger != address(0));
        require(depositArray[_id].timeConfirm > 0 , unicode"Предложение не актуально");
        require(msg.value >= depositArray[_id].priceDeposit, unicode"Недостаточно средств");
        payable (depositArray[_id].pledger).transfer(depositArray[_id].priceDeposit);
        depositArray[_id].pledger = address(0);
        depositArray[_id].priceDeposit = 0;
    }
    // Получение всех недвижимостей
    function getAllObjects () external view returns (Realty[] memory) {
        return realties;
    }
    // Получение всех предложений о дарении
    function getAllGift () external  view returns (Gift[] memory) {
        return giftArray;
    }
    // Получение всех предложений о продаже
    function getAllSale () external view returns (Sale[] memory) {
        return saleArray;
    }
    // Получение всех залогов
    function getAllDeposit () external view returns (Deposit[] memory) {
        return depositArray;
    }    
}

