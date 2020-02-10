class ArticlesController < ApplicationController
  before_action :require_user_logged_in
  before_action :set_article, only: [:show, :edit, :update, :destroy]
  before_action :twitter_client, only: [:create]
  before_action :gcpnla_client, only: [:create]

  # GET /articles
  # GET /articles.json
  def index
    #@articles = Article.all scaffoldから削除
    @articles = Article.order(id: :desc).page(params[:page]).per(20) #scaffoldに追加
  end

  # GET /articles/1
  # GET /articles/1.json
  def show
    @article = Article.find(params[:id]) #scaffoldに追加
  end

  # GET /articles/new
  def new
    @article = Article.new
  end

  # GET /articles/1/edit
  def edit
    @article = Article.find(params[:id]) #scaffoldに追加
  end

  # POST /articles
  # POST /articles.json
  def create
    #@article = Article.new(article_params)
    @article = current_user.articles.build(article_params)
    @article.content, @article.title, @article.score = search_tweet(@article.keyword,@article.tweetid,@article.number,@article.mode,@article.analysisflag)
    
    if @article.save
      flash[:success] = '記事を投稿しました。'
      redirect_to @article
      #redirect_to root_url
    else
      flash.now[:danger] = '記事の投稿に失敗しました。'
      render :new
      #render 'toppages/index'
    end
    
  end

  # PATCH/PUT /articles/1
  # PATCH/PUT /articles/1.json
  def update
    #@article = Article.find(params[:id])
    @article = current_user.articles.build(article_params_edit)
    
    if @article.save
      flash[:success] = '記事は正常に更新されました。'
      redirect_to @article
    else
      flash.now[:danger] = '記事は更新されませんでした'
      render :edit
    end
    
  end

  # DELETE /articles/1
  # DELETE /articles/1.json
  def destroy
    @article.destroy
    flash[:success] = '記事を削除しました。'
    redirect_back(fallback_location: articles_url)
  
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_article
      @article = Article.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def article_params
      #params.require(:article).permit(:keyword, :title, :content, :user_id)
      params.require(:article).permit(:keyword, :tweetid, :number, :mode, :analysisflag)
      # keywordのみnewのviewから受け取る
      # current_user.articles.buil(・・・)により、ユーザに紐づけて投稿を作成->user_id不要
    end
    
     def article_params_edit
      #編集用のストロングパラメーター 
      params.require(:article).permit(:keyword, :tweetid, :title, :content, :score, :number, :mode, :analysisflag)
     end
    
    
    # ============TwitterAPI Natural Language APIの準備 はじめ============
    def twitter_client
        # アクセストークンなどを設定、clientをクラスインスタンス変数(@)としてクラス内で共有する
        @client = Twitter::REST::Client.new do |config|
            
            #credentials.yml.encに記載したキー情報を呼び出すやり方
            config.consumer_key        = Rails.application.credentials.twitter[:CONSUMER_KRY]
            config.consumer_secret     = Rails.application.credentials.twitter[:CONSUMER_SECRET]
            config.access_token        = Rails.application.credentials.twitter[:CONSUMER_TOKEN]
            config.access_token_secret = Rails.application.credentials.twitter[:CONSUMER_TOKEN_SECRET]
            
        end
    end
    
    def gcpnla_client
        # Google Cloud Platform Natural Language APIを使用するための準備
        
        # Instantiates a client
        @language = Google::Cloud::Language.new
    
    end
    
    # ============TwitterAPI Natural Language APIの準備 おわり============
    
    #トレンドを取得して、キーワードとするためのメソッド
    #def get_trendname
    #    trendname = @client.trends_place(23424856).take(1).name # 23424856:日本のtrendを取得
    #    return trendname
    #end

    #Twitterによるキーワード検索&感情分析
    def search_tweet(keyword,tweetid,number,mode,analysisflag)
        
        title = "" #初期化 articlesのtitleに相当
        score = "" #Natural Language APIのscoreの計算結果を格納
        result = @client.oembed(tweetid).html #引用元のツイートを最初に持ってくる
        
        @client.search(keyword, result_type: mode, exclude: "retweets").take(number).each do |tweet|
            #result_type recent:最新、popular:人気、mixed:全て(popular + recent)
            #bumber個分ツイートを検索してくる
            #リツイートは排除
          
          #Debug
          puts tweet.in_reply_to_status_id
          #puts temp.frozen?
          #puts tweet.in_reply_to_user_id
          #puts @client.oembed(tweet.id).html 
          
          if tweet.in_reply_to_status_id.to_s == tweetid
          #リプライ先のツイートIDが引数で与えたツイートIDに一致するものを抽出

            puts "ifの中"
            temp = +@client.oembed(tweet.id).html
            #引用元ツイートが残ったままの埋め込みURL,(+)によりfrozenを解除
            
            result = result + temp.gsub!(/class="twitter-tweet"/, 'class="twitter-tweet" data-conversation="none"') + "<br>\n\n"
            #引用元ツイートを削除する文字列変換(data-conversation="none"追加)を実施
            
            #result = result + @client.oembed(tweet.id).html + "<br>\n\n"
            #tweetの検索結果（埋め込みツイート）を集積してテキスト化する
            
            # ========================== 感情分析 はじめ==========================
            #感情分析の実施フラグ
            if analysisflag
            
              # Detects the sentiment of the text
              response = @language.analyze_sentiment content: tweet.full_text, type: :PLAIN_TEXT
            
              # Get document sentiment from response
              sentiment = response.document_sentiment 
              score = score + sentiment.score.round(1).to_s + ","

            end
            # ========================== 感情分析 おわり==========================
            
          end
        
        end
        
        #tweet検索の結果、何もヒットしなかった場合
        if result == ""
          result = "検索結果無し"
        end
        
        #感情分析検索がOFF、またはtweet検索の結果、何もヒットしなかった場合
        if score == ""
          score = "感情分析OFFまたは無し"
        end
        
        title = keyword + "_" + DateTime.now.to_s
        #titleの設定（keyword_yyyymmddhh:mm?）
        
        return result, title, score
        # resultとtitleをリターン
    end
    
end
