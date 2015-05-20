require 'spec_helper'
require 'models/account'
require 'models/user'

describe AutoIncrement do
  before :all do
    @account1 = Account.create name: 'My Account'
    @account2 = Account.create name: 'Another Account', code: 50

    @user_account1 = @account1.users.create name: 'Felipe', letter_code: 'Z'
    @user_account2 = @account2.users.create name: 'Daniel'
  end

  describe 'initial' do
    it { expect(@account1.code).to eq 1 }
    it { expect(@user_account1.letter_code).to eq 'A' }
  end

  describe 'do not increment outside scope' do
    it { expect(@user_account2.letter_code).to eq 'A' }
  end

  describe 'not set column if is already set' do
    it { expect(@account2.code).to eq 50 }
  end

  describe 'set column if option force is used' do
    it { expect(@user_account1.letter_code).to eq 'A' }
  end

  describe 'locks query for increment' do
    before :all do
      threads = []
      lock = Mutex.new
      @account2 = Account.create name: 'Another Account', code: 50
      @accounts = []
      5.times do |_t|
        threads << Thread.new do
          lock.synchronize do
            @account2 = Account.create name: 'Another Account', code: 50
            5.times do |_thr|
              @accounts << (@account2.users.create name: 'Daniel')
            end
          end
        end
      end
      threads.each(&:join)
    end
    let(:account_last_letter_code) do
      @accounts.sort_by(&:letter_code).last.letter_code
    end

    it { expect(@accounts.size).to eq 25 }
    it { expect(account_last_letter_code).to eq 'E' }
  end
end
