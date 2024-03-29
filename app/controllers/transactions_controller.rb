class TransactionsController < ApplicationController
  before_action :set_transaction, only: [:show, :edit, :update, :destroy]
  before_filter :authenticate_user!, only: [:new, :index]
  #wepay = WePay.new(client_id, client_secret, use_stage, true, api_version)

  def verify
    @transaction = Transaction.find(params[:tran_id])
    is_verified = @transaction.authenticate_otp(params[:code], drift: 90)
    if is_verified
      @transaction.update_attributes(verified: true)
      c=@transaction.campaign
      c.update_attributes(collected: c.collected + @transaction.amount)
    else
      flash[:notice] = 'InValid Code'
    end
    redirect_to @transaction
  end

  def generate_otp_code
    @transaction = Transaction.find(params[:tran_id])
    @campaign  = @transaction.campaign
    number_to_send_to = ''
    send_otp_code(number_to_send_to)
    flash[:notice] = "Sent new OTP code to ur Mobile"
    redirect_to @transaction
  end

  # GET /transactions
  def index
    @transactions = Transaction.all
  end

  # GET /transactions/1
  def show
  end

  # GET /transactions/new
  def new
    @transaction = Transaction.new
    @transaction.campaign_id = params[:campaign_id]

    

    # wepay = WePay.new(client_id, client_secret, use_stage)

    # redirect_uri = "http://myexamplesite.com/wepay"
    # url = wepay.oauth2_authorize_url(redirect_uri)
    # redirect_to(url)

    # response = wepay.oauth2_token(code, redirect_uri)
    # access_token = response['access_token']

    # response = wepay.call('/user', access_token)

    # response = wepay.call('/account/create', access_token, {:name => "test account", "description" => "this is only a test" })

  end

  # GET /transactions/1/edit
  def edit
  end

  # POST /transactions
  def create
    @transaction = Transaction.new(transaction_params)
    @transaction.user_id = current_user.id
    binding.pry
    if @transaction.save
      @campaign  = @transaction.campaign
      number_to_send_to = '+919930443487'
      send_otp_code(number_to_send_to)
      redirect_to @transaction
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /transactions/1
  def update
    if @transaction.update(transaction_params)
      redirect_to @transaction, notice: 'Transaction was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /transactions/1
  def destroy
    @transaction.destroy
    redirect_to transactions_url, notice: 'Transaction was successfully destroyed.'
  end

  private
    def send_otp_code(number_to_send_to)
      client = Twilio::REST::Client.new(TWILIO_CONFIG['sid'], TWILIO_CONFIG['token'])

      # Create and send an SMS message
      binding.pry
      client.account.sms.messages.create(
        from: TWILIO_CONFIG['from'],
        to: number_to_send_to,

        body: "OTP code for #{@campaign.title.slice(0,15)} is #{@transaction.otp_code} with amount #{@transaction.amount}"
      )
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_transaction
      @transaction = Transaction.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def transaction_params
      params.require(:transaction).permit(:amount, :user_id, :campaign_id)
    end

    
end
