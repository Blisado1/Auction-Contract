// defining the types

type auction_storage = {
    auction_end : timestamp;
    highest_bid : tez;
    bidder : address;
}
type return = operation list * auction_storage

let owner_address : address = 
    ("tz1Wv5x5MWbBBYPD6JB6ZTZfWNfg9SsTuy9h" : address)

let main (_parameter, auction_storage : unit * auction_storage) : return =
    
    // check if the auction has ended
    let () = if Tezos.now > auction_storage.auction_end then
        failwith "Sorry, Auction has ended"
    in

    // Check if amount sent is lower than the highest bid
    let () = if Tezos.amount <= auction_storage.highest_bid then
        failwith "Sorry your bid is lower than the current bid"
    in

    // Store the records of the new bid in variables
    let new_bid : tez = Tezos.amount in

    let new_bidder : address= Tezos.sender in

    // Get details of previous bid details from storage
    let previous_bidder : address = auction_storage.bidder in

    let previous_bid : tez = auction_storage.highest_bid in

   
    // Set new highest bid in storage
    let auction_storage = { auction_storage with 
        highest_bid =  new_bid; 
        bidder = new_bidder;
        } 
    in

    // Refund previous bid to previous bidder
    // But check if user address exists, as a security option and if doesn't the contract fails
    let receiver : unit contract =
        match (Tezos.get_contract_opt previous_bidder : unit contract option) with
        | Some (contract) -> contract
        | None -> (failwith ("Not a contract") : (unit contract))
    in
    
    // We will create a transaction to an account and not a contract, so we will use unit as the first parameter and then pass the amount and the receiver address. We need to create a list of operations that we will return at the end of the contract, which, in this case, will be just one, and then return the list as well as our updated token_shop_storage storage at the end of the contract.
    let payout_operation : operation = 
        Tezos.transaction unit previous_bid receiver 
    in

    let operations : operation list = 
        [payout_operation] 
    in

    ((operations: operation list), auction_storage)




