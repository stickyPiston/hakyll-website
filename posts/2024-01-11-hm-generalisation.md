---
title: To generalise or not to generalise your types?
---

I am working on a simple object-oriented programming language
called [dabulang](https://github.com/stickyPiston/dabulang), and my
goal is to make it robust and usable. So for the type checking and type
inference, the internet naturally pointed me to a
[Hindley-Milner type system](https://en.wikipedia.org/wiki/Hindley%E2%80%93Milner_type_system).

There is one problem with using Hindley-Milner in dabulang, however.
As mentioned before, dabulang is an object-oriented language, but the
Hindley-Milner "calculus" is a functional language. Implementing the
type inference algorithm like the tutorials show renders some problems in dabulang.
One of those problems is the way Hindley-Milner deals with definitions of
polymorphic functions and values: _let-polymorphism_.

## Let-polymorphism

Let-polymorphism is based on two rules: one for defining variables and one for
using variables. Whenever we define variables, the value of the variable might
contain free type variables introduced by the type inference algorithm.
For instance, the term $\lambda x.x$ has type $\alpha\to\alpha$ where $\alpha$
is a fresh type variable. But when the programmer wants to bind this term to a
variable and use it multiple times, we get conflicting constraints for the type
variable $\alpha$. Therefore, we need to _generalise_ the type of the defined value,
such that each use of the value can use a new _instantiation_ of its type.

Generalisation is quite an easy process: we take a type $\tau$ and the current
environment $\Gamma$, then we create a type scheme that binds every freely
occurring type variable in $\tau$ that isn't already bound in $\Gamma$. More
formally, we define generalisation using the following function:

$$
\begin{gather*}
\rm{Gen}:\Gamma\times \tau\to\sigma\\
\rm{Gen}=(\Gamma, \tau)\mapsto \forall(\rm{ftv}(\tau)\setminus\rm{ftv}(\Gamma)).\tau
\end{gather*}
$$

where $\tau$ is the set of types, and $\sigma$ the set of type schemes, and
$\rm{ftv}(x)$ denotes the set of free type variables in $x$. With that
definition in mind, we can define type inference for let-in expressions as follows:

$$
\dfrac
  {S_0\Gamma\vdash e_0:\tau_0\quad
    S_1(S_0\Gamma\cup\{x:\rm{Gen}(S_0\Gamma, \tau_0\})\vdash e_1:\tau_1}
  {S_0S_1\Gamma\vdash\textbf{let } x=e_0\textbf{ in }e_1:\tau_1}
  [\rm{Let}]
$$

Instantiation isn't difficult either: we take a type scheme, and consistently replace
every type variable that's bound by the type scheme with a freshly generated
type variable. Again more formally, we define instantiation as another function
as follows:

$$
\begin{gather*}
\rm{inst}:\sigma\to\tau\\
\rm{inst}=(\forall\alpha_1,\ldots,\alpha_n.\tau)\mapsto \tau[\alpha_1:=\rm{fresh},
\ldots,\alpha_n:=\rm{fresh}]
\end{gather*}
$$

where $\rm{fresh}$ denotes a fresh type variable that is free in $\tau$. Inferring
the type of a variable is now as simple as looking up the type scheme in the
environment, and instantiating the found type scheme.

$$
\dfrac
  {x:\sigma\in\Gamma}
  {\emptyset\Gamma\vdash x:\rm{inst}(\sigma)}
  [\rm{Var}]
$$

## To generalise?

Let-polymorphism is a very useful concept in the Hindley-Milner calculus,
since it's the only way to define polymorphic functions and values. That means a
term like the following will be accepted by Hindley-Milner, because $f$ has the
inferred type $\alpha\to\alpha$, and running that through $\rm{Gen}$ gives the
type scheme $\forall\alpha.\alpha\to\alpha$.

$$
\textbf{let }f=\lambda x.x\textbf{ in }(f\ 10, f\ \rm{True})
:\rm{Int}\times\rm{Bool}
$$

Now let's look at a more complex example: let's add some rules for lists.
We add a rule for list literals, that
constraints all the types of the elements to be equal to each other, and then
yields a list of that type. Additionally, we add the cons operation that prepends
an element to a list.

$$
\begin{gather*}
\dfrac
  {S_0\Gamma\vdash e_0:\tau_0,\ldots,S_n\Gamma\vdash e_n:\tau_n,\quad
    \tau\stackrel{U_0}\sim\tau_0,\ldots,\tau\stackrel{U_n}\sim\tau_n}
  {S_0\ldots S_nU_0\ldots U_n\Gamma\vdash[e_0,\ldots,e_n]:\rm{List}[\tau]}
  [\rm{List}\text{-}\rm{lit}]\\
\\
\dfrac
  {S_0\Gamma\vdash e_0:\tau\quad S_1(S_0\Gamma)\vdash e_1:\rm{List}[\tau]}
  {S_0S_1\Gamma\vdash e_0::e_1:\rm{List}[\tau]}
  [\rm{List}\text{-}\rm{cons}]
\end{gather*}
$$

Now using these new concepts, we can infer and check the type of the following
program. Note that we abuse the let-polymorphism here, since $[]:\rm{List}[\alpha]$
and, therefore according to the $[\rm{Let}]$ rule, $x:\forall\alpha.\rm{List}[\alpha]$
is added to the environment. And with the $[\rm{Var}]$ rule, we can instantiate $x$
as both a $\rm{List}[\rm{Int}]$ and a $\rm{List}[\rm{Bool}]$ in the same body.

$$
\textbf{let }x=[]\textbf{ in }(10::x,\rm{True} :: x)
:\rm{List}[\rm{Int}]\times\rm{List}[\rm{Bool}]
$$

As we've seen with functions, the generalisation in the $[\rm{Let}]$ rule and
the instantiation in the $[\rm{Var}]$ rule are hard at work to handle the
polymorphic list. As mentioned before, in the Hindley-Milner calculus,
variables cannot be assigned to after they are defined. But in the case of
imperative or object-oriented languages, reassignment should be allowed,
so can we still use let-polymorphism in those languages?

## Not to generalise?

Consider the following dabulang program. We see that we declare a variable `result`
and assign to elements in it in the for loop. Without going into how to handle
constraint generation between statements, we can try using generalisation and see
what the type of `map` becomes.

```vba
Func map(func, list)
  Let result = [];
  For i = 0 To len(result) Then
    result[i] = func(list[i]);
  End
  Return result;
End
```

`result` is a definition we have seen before, so we can quickly conclude that
$\text{result}:\forall\alpha.\rm{List}[\alpha]$. Now the use of `result` in the for
loop causes it to get instantiated and become a value of type $\rm{List}[\beta]$,
and similarly, the use in the return statement also gets instantiated to a value
of type $\rm{List}[\gamma]$. So the type of `map` is inferred as
$\forall\alpha,\beta,\gamma.(\alpha\to\beta)\times\rm{List}[\alpha]\to\rm{List}[\gamma]$.
This isn't really the expected type for `map`, so what goes wrong here? Well, the
generalisation of `result` causes the value in the return statement to be instantiated
with a type independent of other uses of `result`. Since we reassign
elements of `result` we need to take the extra constraints into account
throughout the entire function body. The solution in this case is simple:
we need to disable generalisation in let statements.

$$
\begin{gather*}
\dfrac
  {S_0\Gamma\vdash e_0:\tau_0\quad S_1(S_0\Gamma\cup\{x:\tau_0\})\vdash e_1:\tau_1}
  {S_0S_1\Gamma\vdash\textbf{let }x=e_0\textbf{ in }e_1:\tau_1}
  [\rm{Let}\text{-}\lnot\rm{Gen}]\\
\\
\dfrac
  {x:\tau\in\Gamma}
  {\emptyset\Gamma\vdash x:\tau}
  [\rm{Var}\text{-}\lnot\rm{inst}]
\end{gather*}
$$

So interestingly, let-polymorphism seems to be tied with immutability. For
immutable variables, it is safe to generalise any free type variables, but for
mutable variables, it can lead to unexpected types. This observation means that
in dabulang, we don't need to throw let-polymorphism out of the window, we just
need to be careful where we apply it. Since top-level functions are immutable, we
can still apply let-polymorphism, and benefit from all of its useful properties.
However, when declaring mutable values, we need to take all of the possible
reassignments into account, and therefore, we cannot generalise these variables.
