---
date: "2017-11-12"
title: "Ideas, Leaders, and Engineers"
tags: ["business", "philosophy", "leadership", "engineering"]
comments: true
---

[The Senior Engineer's Guide to Helping Others Make Decisions](http://silverwraith.com/blog/2017/10/the-senior-engineers-guide-to-helping-others-make-decisions/) is a good read and good advice. I would summarize the advice as:

1. "Seek first to understand, then to be understood" ([Dr. Stephen Covey](https://www.stephencovey.com/7habits/7habits-habit5.php))
1. Lead and guide, don't micromanage
1. Embrace change, which entails embracing other people's thinking and way of doing things

In the first dialog, the senior engineer fails those three points.

Av's blog post made me think...

## Good Ideas

Let me jump right to the punch line: _levels of seniority should not apply to ideas_. Many years ago I realized the following, one of my personal maxims:

<mark>Neither age nor experience guarantee good ideas.</mark>

At the time, I was working with a senior engineer who, I felt, was making bad decisions wrt one project. Overall, the senior engineer was a fantastic developer--one of the best I've ever worked with--but for one project he was proposing crazy ideas. And since you don't know me: I like crazy ideas! So if I'm the person saying, "Uh... that's probably not a good idea.", then it should really give you pause.

Software engineering harbors a contradiction. On the one hand, there is a cultural understanding (more like a bias) that young people are the font of great ideas, innovation, the next Facebook. Therefore, we should listen to them more closely, but more often we make them underlings of senior engineers and treat their ideas as ignorant at best and naïve at worst. But on the other hand, we consider and expect senior engineers to know best. Perhaps great ideas are not the same as knowing best? But if knowing best does not lead to great ideas, why value senior engineers? Moreover, why make young engineers from whom we believe will come the next Facebook follow or learn from senior engineers whom we do not expect the next Facebook? Given this contradiction (and the implicit bias toward younger minds), I think there's little to no value in levels of seniority wrt ideas.

How many years is "senior"? Is there any objective test or measure? A colleague on my team has more experience than me; are we both be "senior"? What if I have more experience in a particular area? I used to do networking, but that was many years ago; am I still still "senior" wrt networking or did I lose the title? Since levels of seniority are fluid, having no clear delineations, I think they have little to no value wrt ideas.

"Okay but what about _years_ of experience?", you say. True, I've been programming 20+ years, but that number is merely quantitative, not qualitative. Not everyone improves with time and practice. I've played chess my whole life, but guess what: I'm terrible. Years are a number, nothing more. If you're a "junior" engineer, some day you might have an idea that's the greatest. And if you're a "senior" engineer who seeks first to understand, some day you will learn something from a "junior" engineer.

Ideas stand on their own. A good idea is a good idea regardless of who proposes it. There are no "senior ideas" or "junior ideas". For myself and my team, although HR lists me as a senior engineer, when it comes to ideas everyone on the team is equal.

"Okay but surely you're not saying _all_ ideas are good or have merit?" True, some ideas are bad. For a typical business, if _any_ engineer suggests not backing up production data, that's a bad idea. This leads me to the next section...

## Sometimes "Oh hell no!" Is Great Leadership

In the third and final dialog of Av's blog post, we see the senior engineer respond:

> Perl. Huh. Well.. there are some issues you might run into later with maintainability because only you and I know Perl. But if you like the solution, and it works, let's do it.

I disagree with that approach. I think the senior engineer is failing to provide more complete leadership. Leading is more than helping another engineer achieve the points in Av's blog post:

* Learning new language
* Implementing a backup solution
* Improved decision making
* Engaging other engineers
* Presenting and refining ideas
* Presenting solutions
* Tracking work

Those are great points, and a leader should help another engineer achieve them. Missing, however are: 

* Avoiding pitfalls
* Adding business value

### Avoiding Pitfalls

To be fair, in the dialog the senior engineer encourages the junior engineer to write really good docs, comment their code, and track their work and decisions. Those are all great ways to avoid various pitfalls, and good leadership needs to go further when ideas entail significant business risk or commitment.

In the example, the junior engineer wants to use a "new" language, i.e. a language that only the two engineers know. Presumably, the team does not know or use the language. I would be very cautious about using a new language because it commits the business to the language, probably for a long time. This is not a decision to make lightly because a common experience in tech is working on a project that's written in a language that, today, seems like an odd choice. When we have the opportunity to choose the language, the choice often affects engineers and the business for years to come:

* For engineers, it becomes a language we should master (if we wish to be masterful in our work). Doing so affects our career. If an engineer dives into front-end development with JavaScript, switching to back-end dev with Go isn't trivial. The senior engineer should discuss and guide how and where the junior engineer spends their time. The best leadership helps us avoid wasting our time. Or, to state it positively: the best leadership helps us make the best use of our time.

* For the business, it must hire and/or train engineers for the language. If the language is popular and trending, no problem; if not, the business can find itself with a system it needs but no one to maintain it. The senior engineer should remind the junior engineer that everyone leaves eventually. This is a lesson engineers learn slowly because it takes years of being the new engineer plus more years of being the next engineer, i.e. the engineer who, today, who must work with a language (or framework, design, architecture, etc.) chosen hastily by engineers in years past.

I would have serious reservations about using a new language. Instead, I would want to leverage current expertise, if team team has it in an appropriate language. If not, I would discuss with the team and one or two levels up in management to see if a new language is something the business is willing to embrace.

Helping other engineers avoid pitfalls is an important part of leading. Knowing that such pitfalls exist is a benefit of experience. However, as Av's blog post points out, don't let avoidance become an excuse, implicitly or explicitly, for shutting down new or different ideas.

### Adding business value

Businesses walk a line between encouraging individuals to think of new and creative solutions vs. doing what has actual business value. (By "business value" I mean generally whatever allows the business to make money and pay its employees; at great businesses, this is a focus on customer needs.) _Individuals must remember that unless the majority of their work adds business value, there won't be a business for them to work at._ Senior engineers qua leaders must strike a balance between what's good (or fun) for engineers and what's good for the business.

Therefore, "if you like the solution, and it works, let's do it" falls short of leadership. By that guidance, engineers can do anything as long as someone likes it and it "works" which, ironically, we can't know until they try. Moreover, there's a higher risk of failure or setbacks because it's a junior engineer with less experience executing a greenfield idea, let alone in a new language.

In the example, daily partial backups probably do add business value. The idea is great; I'm not arguing that. I'm arguing that "because you like it and it works" is not good leadership. Instead, better leadership would say:

> Yeah, daily partial backups are great! That'll both increase data protection and decrease restore time. Perl, however, is not an actively used language these days. Does this require Perl? Since we're all Go and Ruby experts, and those languages are equally good choices for this project, I think we should use one of them. What do you think?

In this way, the senior engineer both embraces and encourages the idea while framing in terms of business value, and questioning the use of a new language addresses the first point: avoiding pitfalls.

## Back in '97

It's not uncommon to hear senior engineers describe how they learned at a young age, learned the hard way, taught themselves through trial and error, etc. In short: they were hackers.

Where I work, there are engineers who were not born when I was programming, teaching myself. And other engineers can say the same about me: I was not born when they were programming and creating the first PCs. [There are still kids today who are self-motivated hackers](https://www.wired.com/story/meet-the-high-schooler-shaking-up-artificial-intelligence/), and they'll enter college then work as experienced programmers. This is an endearing narrative senior engineers often repeat because in past decades it was commonplace, but in 2017 the narrative of 1997 can be an unfair expectation. Let me explain...

I know many software engineers who learned in college, not before, then got a job programming. They were not hackers as kids. They cannot tell you about their first computer, its hardware specs and how they took it apart and rebuilt it. They cannot tell you how their high school gym teacher, being a wise educator who saw potential in a young person, gave them permission to sit out every class so, instead, they could read [Advanced Programming in the Unix Environment](http://a.co/8vz1Wm1). [1] Therefore, encouraging or requiring a junior engineer to hack their way through problems to solution assumes that the engineer wants or needs to learn things the "hacker way".

[1]: Actually, the deal was: I'd lift weight for the first part of class, then I was free to sit out the rest. So Mr. McDougle was doubly wise: exercise body _and_ mind.

The fallacy is applying personal ambition and methods to others. When a senior engineer recounts their younger hacker days, it's often stories of personal exploration. That's great for them, and only them. An engineer who learned programming in college might not have any interest or desire in learning things the hacker way. It's quite possible that, whereas tech is a profound and personal calling for the senior engineer, tech is merely a skill and career for the junior engineer.

In 1997, it was safer to presume that a software engineer had a personal affection for the work. Twenty years later, we must discover and address each engineer as an individual and tailor our conversation and leadership accordingly.

The junior engineer in Av's blog post seems to have a willingness to learn the "hacker way": through hands-on trial and error, a laissez-fair approach. The senior engineer is very hands-off, which is normally good. But if the junior engineer is not a hacker, laissez-faire leadership can do more harm than good. Here's an alternative version of part of the third dialog:

> J: I was thinking, wouldn't it be great if we could just back up what changed every day, rather than everything? It seems like a waste of space.
>
> S: That would be great! I have some ideas on how you could do that, but why don't you go and try a few things yourself first? If you get stuck, let me know.
> 
> J: What are your ideas?
> 
> S: Let's discuss after you've done some initial investigation. I don't want to bias your decisions.
> 
> J: Ok thanks, but I don't know where to begin. I've never written a new backup system before.
> 
> S: Look at existing systems, and go from there. Start with \<name of some backup system>.
> 
> J: Ok...

Two things. First, if we didn't know the context, the backstory, we might interpret the senior engineer as being unhelpful. Perhaps they don't like the junior engineer and they're trying to make their job difficult by not helping. It's sad, but it happens. The point is: laissez-faire leadership is not always well-intentioned. If you're guiding or being guided this way, be sure the leader's intention is benevolent, that they're intentionally giving you freedom, latitude to learn and grown. If true and that's what you want, then great!

Second, not all engineers want such latitude. As this section began by exploring, _not all engineers today are hackers who learned by hands-on trial and error at home and want to learn that way at work_. It's quite possible that the junior engineer wants to work closely with, learn directly from the senior engineer. Senior engineers should not presume that "go and try a few things yourself" is welcomed freedom. For some engineers, it's job stress and apprehension, "Oh shit... This is my first job! I need to make a good impression! I'd better figure it out fast, else I'll get fired!"

I'm not saying senior engineers should always be "hand holding", or do the job of junior engineers. Every engineer needs to contribute: think, research, learn, think more, execute, etc. It's part of the job; it's why we're hired: to think of and implement technical solutions to business needs. I'm saying senior engineers should not assume that the way they learned back in 1997 is how every engineer wants to learn and do their job today.

Here's the conversation I'd have:

> J: I was thinking, wouldn't it be great if we could just back up what changed every day, rather than everything? It seems like a waste of space.
> 
> S: That would be great! I have some ideas on how you could do that. Want to discuss them? Or you want to do some initial research first?
> 
> J: Let's discuss them, then I'll do my own research, and we can talk again later.
> 
> S: Sure. Put some time on my calendar.

My advice to senior engineers helping others:

1. Lead with and offer freedom, latitude to explore and learn the hacker way
1. Offer to work directly with the engineer at the start, to get them started
1. Always be helping the engineer develop their autonomy, at their pace

In twenty more years, 2037, we might be reading: "The AI Guide to Helping Humans Make Decisions".
