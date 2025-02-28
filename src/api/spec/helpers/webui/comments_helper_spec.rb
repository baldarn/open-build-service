RSpec.describe Webui::CommentsHelper do
  describe 'comment_user_role_titles' do
    subject { comment_user_role_titles(comment) }

    context 'when the commenter has a moderator global role' do
      let(:comment) { create(:comment_package) }

      before { comment.user.roles << Role.find_by_title!('Moderator') }

      it { is_expected.to include('Moderator') }
    end

    context 'when the commenter is the maintainer of the commented package' do
      let(:comment) { create(:comment_package) }

      before { comment.commentable.add_maintainer(comment.user) }

      it { is_expected.to include('maintainer') }
    end

    context 'when the commenter is the maintainer of the commented project' do
      let(:comment) { create(:comment_project) }

      before { comment.commentable.add_maintainer(comment.user) }

      it { is_expected.to include('maintainer') }
    end

    context 'when the commenter is the submitter of the commented request' do
      let(:comment) { create(:comment_request) }

      before { comment.user = User.find_by(login: comment.commentable.creator) }

      it { is_expected.to include('Submitter') }
    end

    context 'when the commenter is the maintainer of the target project of the request' do
      let(:comment) { create(:comment_request, :bs_request_action) }

      before do
        action = comment.commentable.bs_request_actions.first
        User.session = create(:admin_user)
        project = create(:project_with_package, package_name: 'package1')
        action.target_project = project
        action.target_package = project.packages.first
        tprj = comment.commentable.bs_request_actions.first.target_project
        Project.find_by_name(tprj).add_maintainer(comment.user)
      end

      it { is_expected.to include('maintainer') }
    end

    context 'when the commenter is the maintainer of the target package of the request' do
      let(:comment) { create(:comment_request, :bs_request_action) }

      before do
        action = comment.commentable.bs_request_actions.first
        User.session = create(:admin_user)
        project = create(:project_with_package, package_name: 'package1')
        action.target_project = project.name
        action.target_package = project.packages.first.name
        project.packages.first.add_maintainer(comment.user)
        comment.commentable.bs_request_actions.first.target_project
        comment.commentable.bs_request_actions.first.target_package
      end

      it { is_expected.to include('maintainer') }
    end

    context 'when the commenter is not the maintainer of the targe project of the request' do
      let(:comment) { create(:comment_request, :bs_request_action) }
      let(:somebody) { create(:user, :with_home) }

      before do
        action = comment.commentable.bs_request_actions.first
        User.session = create(:admin_user)
        project = create(:project_with_package, package_name: 'package1')
        action.target_project = project
        action.target_package = project.packages.first
        tprj = comment.commentable.bs_request_actions.first.target_project
        Project.find_by_name(tprj).add_maintainer(somebody)
      end

      it { is_expected.to be_empty }
    end

    context 'when having several request actions but the user is the maintainer of the second one' do
      let(:comment) { create(:comment_request, :bs_request_action) }

      before do
        create(:bs_request_action_submit_with_diff, bs_request: comment.commentable)
        action = comment.commentable.reload.bs_request_actions.second
        User.session = create(:admin_user)
        Project.find_by_name(action.target_project).add_maintainer(comment.user)
      end

      it { is_expected.to include('maintainer') }
    end
  end
end
