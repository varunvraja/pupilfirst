after 'development:schools', 'development:founders', 'development:faculty', 'development:courses' do
  puts 'Seeding community'

  school = School.first
  course = Course.first

  community = school.communities.create!(name: Faker::Lorem.words(2).join('').titleize)
  CommunityCourseConnection.create!(course: course, community: community)
  community_users = community.users.first(5)

  3.times do
    community_users.each do |question_author|
      question = Question.create!(
        title: Faker::Lorem.sentence,
        community: community,
        description: Faker::Lorem.paragraph(sentence_count = 10, supplemental = false, random_sentences_to_add = 5),
        creator: question_author
      )

      community_users.each do |answer_author|
        next if question_author == answer_author

        answer = Answer.create!(
          question: question,
          creator: answer_author,
          description: Faker::Lorem.paragraph(sentence_count = 10, supplemental = false, random_sentences_to_add = 5)
        )

        AnswerLike.create!(
          answer: answer,
          user: community_users.sample
        )

        answer.comments.create!(
          creator: community_users.sample,
          value: Faker::Lorem.paragraph(sentence_count = 4, supplemental = false, random_sentences_to_add = 5)
        )

        question.touch(:last_activity_at)
      end

      community_users.each do |comment_author|
        question.comments.create!(
          creator: comment_author,
          value: Faker::Lorem.paragraph(sentence_count = 4, supplemental = false, random_sentences_to_add = 5)
        )
      end
    end
  end
end
