class OauthsController < ApplicationController
  skip_before_filter :require_login
  before_filter :require_login, only: :destroy

  # sending user to provider and after authorizing back to callback url
  def oauth
    login_at(auth_params[:provider])
  end

  # this is where magic happens
  def callback
    # this is set to 'github' when user is logging in via Github
    provider = auth_params[:provider]

    if @user = login_from(provider)
      # user has already linked their account with github

      flash[:notice] = "Logged in using #{provider.titleize}!"
      redirect_to root_path
    else
      if logged_in?
        link_account(provider)
        redirect_to root_path
      else
        flash[:alert] = 'You are required to link Github account before using this feature. You can do this by clicking "Link your Github account" after you sign in.'
        redirect_to login_path
      end
    end
  end

  # user can unlink their account from oauth provider
  def destroy
    provider = params[:provider]

    authentication = current_user.authentications.find_by_provider(provider)
    if authentication.present?
      authentication.destroy
      flash[:notice] = "You have succesfully unlinked your #{provider.titleize} account."
    else
      flash[:alert] = "You do not currently have a linked #{provider.titleize} account."
    end

    redirect_to root_path
  end

  private

  def link_account(provider)
    if @user = add_provider_to_user(provider)
      # storing user's Github login.
      # @user.update_attribute(:github_login, @user_hash[:user_info]['login'])
    else
      flash[:alert] = "There was a problem linking your Github account."
    end
  end

  def auth_params
    params.permit(:code, :provider)
  end
end
