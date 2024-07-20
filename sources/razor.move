module razor_token::razor_token {
  use std::signer;
  use std::string::{utf8};

  use aptos_std::event;

  use aptos_framework::account;
  use aptos_framework::coin;

  const RAZOR_TOKEN: address = @razor_token;
  const ZERO_ACCOUNT: address = @zero_address;

  const ERROR_ONLY_OWNER: u64 = 1;

  struct Razor {}

  struct TransferOwnershipEvent has drop, store {
    old_owner: address,
    new_owner: address
  }

  struct TransferEvent has drop, store {
    from: address,
    to: address,
    amount: u64
  }

  struct RazorTokenInfo has key {
    mint: coin::MintCapability<Razor>,
    freeze: coin::FreezeCapability<Razor>,
    burn: coin::BurnCapability<Razor>,
    owner: address,
    transfer_ownership_event: event::EventHandle<TransferOwnershipEvent>,
    transfer_event: event::EventHandle<TransferEvent>,
  }

  fun init_module(sender: &signer) {
    let owner = signer::address_of(sender);
    let (burn, freeze, mint) = coin::initialize<Razor>(
      sender,
      utf8(b"Razor token"),
      utf8(b"RZR"),
      8,
      true
    );

    move_to(sender, RazorTokenInfo {
      mint: mint,
      freeze: freeze,
      burn: burn,
      owner: owner,
      transfer_ownership_event: account::new_event_handle<TransferOwnershipEvent>(sender),
      transfer_event: account::new_event_handle<TransferEvent>(sender),
    })
  }

  fun only_owner(sender: &signer) acquires RazorTokenInfo {
    let sender_addr = signer::address_of(sender);
    let razor_info = borrow_global<RazorTokenInfo>(RAZOR_TOKEN);
    assert!(sender_addr == razor_info.owner , ERROR_ONLY_OWNER);
  }

  public entry fun transfer_ownership(sender: &signer, new_owner: address) acquires RazorTokenInfo {
    only_owner(sender);
    let old_owner = signer::address_of(sender); 
    let razor_info = borrow_global_mut<RazorTokenInfo>(RAZOR_TOKEN);
    razor_info.owner = new_owner;
    event::emit_event<TransferOwnershipEvent>(
      &mut razor_info.transfer_ownership_event,
      TransferOwnershipEvent {
        old_owner,
        new_owner
      }
    );
  }

  public entry fun mint(sender: &signer, amount: u64) acquires RazorTokenInfo {
    only_owner(sender);
    let sender_addr = signer::address_of(sender);
    let razor_info = borrow_global_mut<RazorTokenInfo>(RAZOR_TOKEN);
    if (!coin::is_account_registered<Razor>(sender_addr)) {
      coin::register<Razor>(sender);
    };

    coin::deposit(sender_addr, coin::mint(amount, &razor_info.mint));
    event::emit_event<TransferEvent>(
      &mut razor_info.transfer_event,
      TransferEvent {
        from: ZERO_ACCOUNT,
        to: sender_addr,
        amount
      }
    );
  }

  public entry fun transfer(sender: &signer, to: address, amount: u64) acquires RazorTokenInfo {
    let from = signer::address_of(sender);
    coin::transfer<Razor>(sender, to, amount);
    let razor_info = borrow_global_mut<RazorTokenInfo>(RAZOR_TOKEN);
    event::emit_event<TransferEvent>(
      &mut razor_info.transfer_event,
      TransferEvent {
        from,
        to,
        amount
      }
    );
  }

  public entry fun register(sender: &signer) {
    let sender_addr = signer::address_of(sender);
    if (!coin::is_account_registered<Razor>(sender_addr)) {
      coin::register<Razor>(sender);
    };
  }
}