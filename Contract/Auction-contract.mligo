// defining the types
type auction_data = {
    item_name : string;
    auction_end : timestamp;
    highest_bid : tez;
    highest_bidder : address;
    no_of_bids : nat;
}

type auction_storage = (nat, auction_data) map

type return = operation list * auction_storage

let owner_address : address = 
    ("tz1Wv5x5MWbBBYPD6JB6ZTZfWNfg9SsTuy9h" : address)

let main (item_index, auction_storage : nat * auction_storage) : return =

    // Using pattern matching to get a particular item auction from auction storage
    let auction : auction_data =
        match Map.find_opt (item_index) auction_storage with
        | Some a -> a
        | None -> (failwith "Item auction not found" : auction_data)
    in
    
    // check if the auction has ended
    let () = if Tezos.now > auction.auction_end then
        failwith "Sorry, Auction has ended"
    in

    // Check if amount sent is lower than the highest bid
    let () = if Tezos.amount <= auction.highest_bid then
        failwith "Sorry your bid is lower than the current bid"
    in

    // Store the records of the new bid in variables
    let new_bid : tez = Tezos.amount in

    let new_bidder : address = Tezos.sender in

    // Get details of previous bid details from storage
    let previous_bidder : address = auction.highest_bidder in

    let previous_bid : tez = auction.highest_bid in

   
    // Update auction data with new auction details
    let updated_auction_data = { auction with 
        highest_bid =  new_bid; 
        highest_bidder = new_bidder;
        no_of_bids = abs (auction.no_of_bids + 1) 
        } 
    in

    // Update in storage
    let auction_storage = Map.update
        item_index 
        (Some updated_auction_data)
        auction_storage
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
