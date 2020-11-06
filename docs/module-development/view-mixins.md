# Mastering view mixins

In this tutorial we will look at how to register areas for view mixins, enabling other modules to extend your views. We then look at some advanced use cases of view mixins.

You have <a href="/module-development/module-development">used view mixins before</a> to extend existing views with a new module (if you haven't, <a href="/module-development/module-development">start there</a> and come back later). But how can you enable others to extend the views of <em>your</em> module? Let's have a look at how registering new areas for mixins works.

## Implementing a new area for view mixins


Implementing a new area for view mixins is not a great deal. Everything happens in the view so no controllers need to be changed if new mixins are added (especially handy for mixins in the global navbar)!

View mixins are basically no more than a dynamic usage of the <code>&#64;include</code> control structure of the <a href="http://laravel.com/docs/5.5/blade">Blade templating engine</a>. With <code>&#64;include</code> you can take a view and insert it into another view making view modularization and separation of concerns possible. Adding a view mixin to a view is nothing else than <code>&#64;include</code>-ing it, except the name of the view to load is dynamically fetched from the <code>Biigle\Services\Modules</code> service.

This injection mechanism is conveniently implemented as the <code>&#64;mixin</code> directive in BIIGLE. This directive can be used to include all views that match a particular name for view mixins. Let's take a look at how the dashboard view handles including the mixins:
<pre><code>&#64;mixin('dashboardMain')
</code></pre>

The directive queries and includes all view mixins with the name <code>dashboardMain</code> that have been registered with the module's service.

Following the <a href="http://en.wikipedia.org/wiki/Convention_over_configuration">convention over configuration</a> paradigm, if a module wants to add a mixin to the <code>dashboard</code> view, the mixin should be called <code>dashboard</code>, too (resulting in <code>views/dashboard.blade.php</code> in the module). If a view has multiple areas reserved for mixins, these identifiers can differ. We'll cover that in the next section.

Now you know how view mixins essentially work. Using the code snippet from above as an example, you are able to allow view mixins to be added to a view of your own module. Let's now have a look at some advanced use cases for view mixins.

## Asset mixins and multiple mixins per view

Until now we have only talked about registering <em>one</em> area for view mixins per page. There are use cases, though, where you'd want or are even required to have multiple of those areas on one page. Let's take a look at one of the situations where multiple areas for view mixins are necessary.

Having the example of the dashboard mixins still in mind, think about what would happen if we tried to add a custom style to the elements of a mixin. "Of course", you'd say, "there is the <a href="/module-development/custom-assets#publishing-css"><code>styles</code> stack</a> we can append our CSS to." But the downside of this approach is: the custom <code>style</code> tag is appended <em>each time</em> the mixin is included. While this is fine for a regular mixin that is included only once, it becomes a problem if a view mixin is included in a loop. So for each iteration of the loop one custom style tag would be appended to the page. There is a better way to do this.

In fact, there is nothing preventing us to implement a separate "style" mixin and add it to the dashboard. That's exactly what is already provided by the dashboard, looking like this:

<pre><code>&#64;push('styles')
   &#64;mixin('dashboardStyles')
&#64;endpush
</code></pre>

Any mixin registered for <code>dashboardStyles</code> will be appended once to the <code>styles</code> section of the dashboard. Now, if we wanted to add a custom style we would create a mixin called <code>views/dashboardStyles.blade.php</code> looking like this:

<pre><code>&lt;link href="@{{ asset('vendor/module/styles/main.css') }}" rel="stylesheet"&gt;
</code></pre>

And&mdash;in the service provider&mdash;register it to the dashboard styles section:

<pre><code>$modules->register('module', ['viewMixins' => ['dashboardStyles']]);
</code></pre>

Now the custom style is included only once in the dashboard but available to all the multiple instances of the mixin. The same holds for custom scripts (there is a <code>dashboardScripts</code> mixin area). Aside from styles and scripts of nested mixins, you can use this technique to specify multiple arbitrary areas for view mixins on one page, e.g. one for a sidebar, title bar or the content each.

## Conclusion

Now we have de-mystified the mechanisms behind view mixins and you know how to register areas for view mixins, use mixins in loops and in which situations asset mixins are required. You can now consider yourself a fully qualified BIIGLE module developer!
