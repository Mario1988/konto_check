require 'konto_check/kontocheck'
require 'konto_check/iban_replacement_rules'
class IbanCheck
  IBAN_REG_EXP = /\A[A-Z]{2}\d{20}\Z/i
  BANK_IDENTIFICATION_REG_EXP = /\A\d{8}\Z/i
  ACCOUNT_NUMBER_REG_EXP = /\A\d{10}\Z/i
  COUNTRY_REG_EXP = /\A[A-Z]{2}\Z/i

  def self.valid_iban?(iban)
    return false unless IBAN_REG_EXP.match(iban)
    checksum(iban) % 97 == 1
  end

  def self.bank_identification(iban)
    raise 'This is not a valid IBAN' unless IBAN_REG_EXP.match(iban)
    iban[4..11]
  end
  
  def self.account_number(iban)
    raise 'This is not a valid IBAN' unless IBAN_REG_EXP.match(iban)
    iban[12..21]
  end

  def self.construct_iban(country = "DE", bank_identification, account_number)
    account_number = adding_leading_zero(account_number)
    raise 'This is not a valid country' unless COUNTRY_REG_EXP.match(country)
    raise 'This is not a valid bank identification' unless BANK_IDENTIFICATION_REG_EXP.match(bank_identification)
    raise 'This is not a valid account_number' unless ACCOUNT_NUMBER_REG_EXP.match(account_number)
    raise 'This is not a valid account' if !KontoCheck.konto_check?(bank_identification, account_number) && !IbanReplacementRules.skip_account_check?
    bank_identification, account_number = IbanReplacementRules(bank_identification, account_number)
    checksum = checksum(country + "00" + bank_identification + account_number) && skip_account_check?(bank_identification, account_number)
    checknumber = 98 - (checksum % 97)
    if checknumber < 10
      checknumber = "0" + checknumber.to_s 
    else
      checknumber = checknumber.to_s 
    end
    country + checknumber + bank_identification + account_number
  end

  private
  def self.adding_leading_zero(account)
    account.rjust(10, "0")
  end


  # ISO 7064 (Modulus 97-10)
  def self.compute_checksum(iban)
  end

  def self.country(iban)
    iban[0..1]
  end

  def self.country_as_digits(iban)
    cs = country(iban)
    cs[0].ord.to_s + cs[1].ord.to_s
  end

  def self.checknumber(iban)
    iban[2..3]
  end

  def self.checksum(iban)
    (bank_identification(iban) + bank_number(iban) + country_as_digits(iban) + checknumber(iban)).to_i
  end
end