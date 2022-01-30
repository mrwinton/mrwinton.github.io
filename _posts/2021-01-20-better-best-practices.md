---
layout: post
title: Better best practices
date: 2022-01-20 13:42:37 +0200
active: posts
tags: writing
---

Have you ever received a code review that went something along the lines of:

> There are a few places that I've commented which don't follow the best
> practices documented [here](https://example.com/), let's fix up before
> proceeding!

Engineering teams commonly align on practices that we believe encourage good
outcomes in a `best-practices.md` document or similar. These documents are the
melting pot in which company history, community standards, new initiatives and
hard-earned bug fix lessons meet. So it is only natural for reviews like the one
above to occur for changes to be consistent with the `best-practices.md`.

All good, right? Yes, but no.

I believe there are a couple of points of friction with this process.

First, the process inherently relies on the team's ability to recall and
evaluate every practice, in every change, in every code review, in the earnest
hope that bad practices don't slip through.

Second, the process can dilute the signal to noise ratio of the code review,
wherein the worst-case scenario, reviewers and reviewees miss opportunities for
discussion on nuances of the change itself.

So at Velory, we wondered how we could improve this process. Making it easier to
apply our best practices while tightening the feedback loop so that issues are
caught long before code review.

Imagine the nirvana when you are writing code that would introduce a bad
practice and your editor gave the instant feedback, "Hi, avoid Foo. Use Bar
instead", that would be delightful. That's what we're after.

## Towards nirvana

We use Rails to develop our applications and [RuboCop](https://rubocop.org/) to
lint our Ruby code. RuboCop does a marvellous job of checking and maintaining
code style through _Cops_ — rules that identify issues, and optionally
automatically fix them too.

At Velory, our first step on this journey has been through leveraging RuboCop.
By synthesising our best practices into Cops we are essentially able to lint our
best practices — consistently✅ and with a short feedback loop✅!

A reasonable workflow for turning a practice into a Cop has been to:

1. Choose a best practice
 
   Not all best practices are equal, but a good place to start are best
   practices that are `grep(1)`-able. In this example, we can use:

   ```markdown
   - Avoid `let` and `let!` in specs, prefer four-phase test style
   ```

   Which is `grep(1)`-able with:

   ```shell
   grep 'let(.*)' -r spec/**/*.rb
   ```

2. Identify examples

   Often there are a few ways in which a bad practice can be written, so
   identifying these ways helps towards writing a water-tight Cop.

   ```ruby
   # bad
   let(:foo) { "foo" }

   # bad, bad
   let!(:bar) { "bar" }
   ```

3. Write failing specs

   Using the examples we can now write failing specs that will guide the
   implementation.

   ```ruby
   require "spec_helper"
   require "rubocop"
   require "rubocop/rspec/support"
   require "rubocop/cop/velory/lets_not"

   RSpec.describe RuboCop::Cop::Velory::LetsNot do
     include RuboCop::RSpec::ExpectOffense

     it "adds offenses for uses of `let`" do
       expect_offense(<<~RUBY)
         let(:foo) { "foo" }
         ^^^^^^^^^ Avoid `let` and `let!`. Instead inline the 
                   instance within the `it` block to follow the 
                   four-phase test pattern.
       RUBY
     end

     it "adds offenses for uses of `let!`" do
       expect_offense(<<~RUBY)
         let!(:bar) { "bar" }
         ^^^^^^^^^^ Avoid `let` and `let!`. Instead inline the 
                    instance within the `it` block to follow the 
                    four-phase test pattern.
       RUBY
     end

     def cop
       @_cop ||= RuboCop::Cop::Velory::LetsNot.new
     end
   end
   ```

   This is in my opinion the most important step. Here we design our developer
   experience, and to make it a delightful one, I recommend using an actionable
   message. So the developer understands the `why` of the offense and is
   equipped with the context to successfully move forwards with a solution.

4. Write the Cop

   This is the ["Draw the rest of the
   Owl"](https://knowyourmeme.com/memes/how-to-draw-an-owl) step, where we need
   to be familiar with how RuboCop matches code.

   A tip for writing Cops where the example code is `grep(1)`-able is to start with
   the `on_send` matcher and `node` instance methods to find matches. This
   approach takes us pretty far and is all we require for our "Let's Not" best
   practice.

   ```ruby
   require "rubocop"

   class RuboCop::Cop::Velory::LetsNot < RuboCop::Cop::Base
     MSG =
       "Avoid `let` and `let!`. Instead inline the instance " \
       "within the `it` block to follow the four-phase test " \ 
       "pattern."

     def on_send(node)
       return unless node.command?(:let) || node.command?(:let!)

       add_offense(node)
     end
   end
   ```

5. Run on the project

   Once the specs are green it's time to run the Cop on the project!

   ```shell
   ❯ bundle exec rubocop
   Inspecting 1155 files
   ......................CC...........C.............C..............

   1155 files inspected, 43 offenses detected
   ```

   With RuboCop linting our "Let's Not" best practice we find fourty-three
   existing offenses in one of our projects. Finding existing offenses to the
   rule is not an entirely surprising result, c'est la vie. However, on closer
   inspection, all of these offenses are used within `shared_examples`.

   In scenarios like this we have an excellent opportunity to evaluate the best
   practice as a team, questioning:
   - is this an exception to the best practice?
   - is it really a best practice if we have gone against it _X_ times?
   - should we write out the existing offenses?

   If the team thinks it's an exception, then we can loop back to step three,
   refine our examples and update the Cop with the exception in mind. If the
   team thinks it's no longer a best practice, we can delete it. And if the team
   thinks that we should write out the offenses we can use `rubocop
   --auto-gen-config` and leverage [shitlist driven
   development](https://sirupsen.com/shitlists).

## Parting Thoughts

Encoding your `best-practices.md` document with RuboCop is not a drop-in
replacement, but it can be an excellent tool in your team's toolbox for
tightening these feedback loops and ensuring that best practices are held.

Writing custom Cops is not always straightforward and some best practices are
too subjective to be converted. But that's OK. We can delegate our objective
best practices to RuboCop and save our thinking caps for the things that matter.

For further reading I recommend [RuboCop's custom Cop development guide](https://docs.rubocop.org/rubocop/development.html),
[EvilMartian's blog post on custom Cops](https://evilmartians.com/chronicles/custom-cops-for-rubocop-an-emergency-service-for-your-codebase), as well as the open sourced custom
Cops from [Airbnb](https://github.com/airbnb/ruby), [Discourse](https://github.com/discourse/rubocop-discourse), [GitHub](https://github.com/github/rubocop-github), [GitLab](https://gitlab.com/gitlab-org/rubocop-gitlab-security) and [Shopify](https://github.com/Shopify/rubocop-sorbet).

Finally, here is our finished "Let's Not" best practice which has been refined
to "Let's Not (Outside Of Shared Examples)":

```ruby
require "rubocop"

class RuboCop::Cop::Velory::LetsNot < RuboCop::Cop::Base
  MSG =
    "Avoid `let` and `let!`. Instead inline the instance within " \
    "the `it` block to follow the four-phase test pattern. " \
    "Shared examples are an exception to this rule."

  def_node_matcher :in_shared_example?, <<-PATTERN
    {
      (block (send _ #shared_example_context? ...) ...)
    }
  PATTERN

  def on_send(node)
    return unless let_used?(node) && !in_shared_example_block?(node)

    add_offense(node)
  end

  private

  def let_used?(node)
    node.command?(:let) || node.command?(:let!)
  end

  def in_shared_example_block?(node)
    node.each_ancestor(:block).any?(&method(:in_shared_example?))
  end

  def shared_example_context?(element)
    %w[
       it_behaves_like 
       it_should_behave_like 
       include_examples 
       shared_examples
     ].include?(element.to_s)
  end
end
```

And with that, bliss:

```shell
❯ bundle exec rubocop
Inspecting 1155 files
................................................................

1155 files inspected, no offenses detected
```
