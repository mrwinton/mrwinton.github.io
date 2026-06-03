---
layout: post
title: Better best practices
date: 2022-01-20 13:42:37 +0200
active: posts
tags: writing
---

A code review like this is familiar:

> There are a few places that I've commented which don't follow
> _best-practices.md_, let's fix before proceeding

A `best-practices.md` file is useful right up until it depends on everybody
remembering it in the middle of a review.

That creates two problems.

First, it relies on reviewers remembering every rule on every change.

Second, it spends review time on things that should have been caught earlier,
which means less time on the change itself.

At Velory we wanted a tighter loop: less recall, less review churn, faster
feedback.

The idea is simple. You write code, drift into a bad practice, and your editor
immediately tells you what to do instead.

## Towards nirvana

We use [RuboCop](https://rubocop.org/) to lint Ruby. RuboCop's model is
straightforward: write a Cop, define the offense, and let the tool catch it
consistently.

So we started turning best practices into Cops.

The workflow looked like this:

1. Choose a best practice
 
   Start with a rule that is easy to detect. In this case:

   ```markdown
   - Avoid `let` and `let!` in specs, prefer four-phase test style
   ```

   Which is `grep(1)`-able with:

   ```shell
   grep 'let(.*)' -r spec/**/*.rb
   ```

2. Identify examples

   Find the shapes the bad pattern can take.

   ```ruby
   # bad
   let(:foo) { "foo" }

   # bad, bad
   let!(:bar) { "bar" }
   ```

3. Write failing specs

   Let the examples drive the implementation.

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

   This is the most important part. The message should tell the developer what
   is wrong, why it matters, and what to do next.

4. Write the Cop

   This is the ["draw the rest of the
   owl"](https://knowyourmeme.com/memes/how-to-draw-an-owl) step.

   For rules where the example is `grep(1)`-able, starting with `on_send` and a
   few `node` helpers gets you surprisingly far. That was enough here.

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

   Run it across the project.

   ```shell
   ❯ bundle exec rubocop
   Inspecting 1155 files
   ......................CC...........C.............C..............

   1155 files inspected, 43 offenses detected
   ```

   Our "Let's Not" Cop found forty-three existing offenses in one project. On
   inspection, every one of them lived inside `shared_examples`.

   That is useful. It forces the team to ask:
   - is this an exception to the best practice?
   - is it really a best practice if we have gone against it _X_ times?
   - should we write out the existing offenses?

   If it is a real exception, go back to the examples and encode that nuance. If
   it is no longer a best practice, delete the rule. If the rule stands, use
   `rubocop --auto-gen-config` and lean on [shitlist driven
   development](https://sirupsen.com/shitlists).

## Parting thoughts

Encoding your `best-practices.md` document with RuboCop is not a drop-in
replacement, but it can be an excellent tool in your team's toolbox for
tightening these feedback loops and ensuring that best practices are held.

Writing custom Cops is not always straightforward and some best practices are
too subjective to be converted. But that's OK. We can delegate our objective
best practices to RuboCop and save our thinking caps for the things that matter.

For further reading I recommend [RuboCop's custom Cop development guide](https://docs.rubocop.org/rubocop/development.html),
[EvilMartian's blog post on custom Cops](https://evilmartians.com/chronicles/custom-cops-for-rubocop-an-emergency-service-for-your-codebase), as well as the open sourced custom
Cops from [Airbnb](https://github.com/airbnb/ruby), [Discourse](https://github.com/discourse/rubocop-discourse), [GitHub](https://github.com/github/rubocop-github), [GitLab](https://gitlab.com/gitlab-org/rubocop-gitlab-security) and [Shopify](https://github.com/Shopify/rubocop-sorbet).

Here is the finished rule, refined to "Let's Not (Outside Of Shared Examples)":

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
