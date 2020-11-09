# Module development

In this tutorial you will learn what PHP packages are, how they are developed and how you can create a basic BIIGLE module by implementing your own package.

## Basics

BIIGLE is based on <a href="http://laravel.com/">Laravel</a>, a PHP framework for modern web applications. Laravel is designed in an object oriented and very modular fashion, making it easily extensible with custom modules. BIIGLE is designed as a core application, providing user and database management, the RESTful API and some basic views (the dashboard or settings, for example). Any additional functionality - like project management - is added as a separate module, keeping the codebase clean and manageable.

By implementing a custom module and installing or disabling modules developed by others, you can easily extend BIIGLE and shape it to your needs, without having to dig deep into the core application. Using <a href="https://getcomposer.org/">Composer</a>, the most popualar dependency manager for PHP packages, and <a href="https://packagist.org/">Packagist</a> you can even share your BIIGLE modules with others.

So let's have a quick look at how PHP package development usually works.

### Composer


In earlier days of PHP, you typically used libraries developed by others using the <code>require</code> keyword. When developing a large application having lots of dependencies, this method becomes very cumbersome an error-prone; not to mention the performance drawbacks of always loading every dependency. This is where Composer comes in.

Composer is a dependency manager for PHP packages that makes managing dependencies of a large PHP application very easy. With a single <code>composer.json</code> configuration file, Composer takes care of downloading all the files and generating an <code>autoload.php</code> file. By <code>require</code>-ing this file, you are able to use all the dependencies you configured. In our case, Laravel takes care of the autoloading.

### Package development

The <code>composer.json</code> is also used for developing new packages (similar to the <code>package.json</code> for Node.js modules). Each package has such a file, containing the dependencies of the package or the package name, for example. Take a look at the <code>composer.json</code> of the BIIGLE annotations package:

```
{
   "name": "biigle/annotations",
   "require": {
      "biigle/volumes": "dev-master"
   },
   "autoload": {
      "psr-4": {
         "Biigle\\Modules\\Annotations\\": "src"
      }
   }
}
```

First, the name of the package is defined as <code>biigle/annotations</code>. Packages are always namespaced like this, identifying the developer in the first part and the name of the package in the second. In this case the developer is <code>biigle</code> because the annotations package is developed by the BIIGLE core team. For your own packages you might want to use your name or the name of your organization.

Second, the dependencies of the package are declared. Here, the annotations package requires the <code>biigle/volumes</code> package (since otherwise there is no way reaching the annotation tool, but it can have other reasons, too).

Last, the namespace of the PHP classes of this package is defined. The <code>autoload</code> section of this configuration tells composer that every file it finds in the <code>src</code> directory belongs to the <code>Biigle\Modules\Annotations</code> namespace. Any further namespacing inside of this namespace is reflected by the directory structure in <code>src</code>.

This is everything you need to know to understand the more detailed description of developing a package below; all you need for a new package is a directory containing a <code>composer.json</code>.

### Publishing packages


By default, Composer looks for packages in the <a href="https://packagist.org/">Packagist</a> package repository. This is a convenient way of publishing packages to a broad audience. But you might want to keep your package private in some cases, either because it is still in development or you simply don't want to publish it. The good news is that you can still use Composer! The local/private alternative to Packagist is a version contol system (VCS) like <a href="http://git-scm.com/">Git</a> that you should use for developing, anyway.

The VCS works just like the package repository, having master and develop branches as well as tagged versions. All you have to do is tell Composer to look at your private repository, too, while searching for packages. Have a look at the <a href="https://getcomposer.org/doc/05-repositories.md#vcs">Composer documentation</a> for more information.

## Setting up a new module

Having learned all the basics, let's now walk through the process of creating a new module. If you have a local installation of BIIGLE, you should follow along, implementing, and see how it works.

Our module should add new a panel to the BIIGLE dashboard displaying a random <a href="https://github.com/laravel/framework/blob/feb0cee6777daf487ef01b5a0c744d155ac8f057/src/Illuminate/Foundation/Inspiring.php">inspiring quote</a>.

<blockquote>
   Well begun is half done
   <footer>Aristotle</footer>
</blockquote>

### VCS and directory structure

In this tutorial we will use Git as VCS but you should be able to follow along with Mercurial or even Subversion just fine. So let's begin by creating a new repository for our module.

```
git init biigle-quotes
```
      
In the repository, we then create a new <code>src</code> directory and the <code>composer.json</code> file of the module with the following content:
     
```
{
   "name": "biigle/quotes",
   "autoload": {
      "psr-4": {
         "Biigle\\Modules\\Quotes\\": "src"
      }
   }
}
```

You see, our new module is called <code>biigle/quotes</code> but you are free to use your personal name prefix, too. In the autoload section, we define our module to reside in the <code>Biigle\Modules\Quotes</code> namespace. You can choose your own namespace here, too but <code>Biigle\Modules</code> is a good way to keep things organized.

Normally you would start implementing now, but our new module still lacks a few things to integrate cleanly with Laravel.

### Service provider

Each package for Laravel contains one or more <a href="http://laravel.com/docs/5.5/providers">service provider</a> classes. These classes, among other things, tell Laravel where to find the package configuration, views or translation files. So let's create a file called <code>src/QuotesServiceProvider.php</code> with the following content:

<pre><code>&lt;?php

namespace Biigle\Modules\Quotes;

use Illuminate\Support\ServiceProvider;

class QuotesServiceProvider extends ServiceProvider {

   /**
   * Bootstrap the application events.
   *
   * @return void
   */
   public function boot()
   {
      //
   }

   /**
   * Register the service provider.
   *
   * @return void
   */
   public function register()
   {
      //
   }
}
</code></pre>

This skeleton is enough for now, we'll populate it later on. But it already enables us to require and install the new module to our BIIGLE application.

### Installing the module

Before the module can be installed, though, we need to make our first commit to the repository:

```
git add .
git commit -m "Initial commit"
```

When developing a real module (using Git), you now normally would create a bare remote repository on a server all developers can access, and push the first commit to this repository. But for this tutorial we can stick to the local repository, as well.

Having the repository set up, let's switch to our BIIGLE installation and append it to the known repositories in the <code>composer.json</code>. <a href="https://getcomposer.org/download/">Install Composer</a> first if you haven't already. Then run:

```
composer config repositories.quotes vcs /local/path/to/biigle-quotes
```
      
Next add our new module to the required packages:
     
```
composer require biigle/quotes --prefer-source
```

That was it! You now can find a cloned copy of the module repository in the <code>vendor/biigle/quotes</code> directory (the <code>biigle/quotes</code> part is the module name, so the directory names may be different if your module name is different).

Since the new directory is just a clone of the original repository, we can use it for development from now on. Like this you can see all the changes you make live in the application before committing or pushing them. Even more important: You can test the module in the complete application environment! But more on that in another tutorial.

We're not done with installing the new module, though. Laravel still has to be told, to <em>use</em> the module, too. To activate the module, open the <code>config/app.php</code> file, scroll down to the <code>'providers'</code> array and append the service provider of our module:

```
'providers' => [
   // ...
   Biigle\Modules\Quotes\QuotesServiceProvider::class,
]
```

Laravel <a href="https://laravel.com/docs/5.5/packages#package-discovery">package discovery</a> works here, too, but adding the service provider manually to the providers array is the method of choice if the order in which the modules are loaded is important.

Now we are finally done and the new module is installed and activated. Adding a new module to the <code>composer.json</code> and appending the service provider to the <code>app.php</code> is the usual procedure of installing a new BIIGLE module. To deactivate a module, simply comment out the line in the <code>'providers'</code> array (but be sure that this doesn't break any dependencies).

## Developing the module

Although the module is already working, it doesn't do anything yet. The service provider is still empty and we don't have any content. Let's fix that.

As you'll recall we like to add a new section to the BIIGLE dashboard, displaying an inspiring quote.

<blockquote>
   Simplicity is the ultimate sophistication.
   <footer>Leonardo da Vinci</footer>
</blockquote>

This requires us to modify the existing dashboard view somehow. BIIGLE has a mechanism to do just that, called <em>view mixins</em>, that allows modules to inject components into predefined spaces of existing views.

First, we have to create a new view of the module, containing the code of the new dashboard section. In Laravel, views are usually located in <code>resources/views</code>, so let's create the new file <code>src/resources/views/dashboardMain.blade.php</code> in our module repository, with the following content:

<pre><code>&lt;div class="panel panel-default"&gt;
   &lt;div class="panel-heading"&gt;
      &lt;h3 class="panel-title"&gt;Inspiring Quote&lt;/h3&gt;
   &lt;/div&gt;
   &lt;div class="panel-body"&gt;
      &lt;blockquote&gt;
         @{{ Illuminate\Foundation\Inspiring::quote() }}
      &lt;/blockquote&gt;
   &lt;/div&gt;
&lt;/div&gt;
</code></pre>

You see that we can use the entire palette of <a href="https://getbootstrap.com/docs/3.4/">Bootstrap 3</a> classes for styling without having to set anything up. The actual quote is echoed using the <code>@{{&nbsp;}}</code> control structure of the Laravel <a href="https://laravel.com/docs/5.5/blade">Blade templating engine</a>.

Calling the new view <code>dashboardMain.blade.php</code> is essential here, since the view has to have the same name as the identifier of registered space for view mixins. Usually views only register one such space so taking the view name as identifier makes sense. For the dashboard, the ID is <code>dashboardMain</code> so our view mixin must be called <code>dashboardMain</code>, too.

Next, we have to tell Laravel that our module <em>has</em> any views in the first place. To do so, add the following to the <code>boot</code> function of the modules service provider class:

```
$this->loadViewsFrom(__DIR__.'/resources/views', 'quotes');
```

This tells Laravel to look for views of the <code>quotes</code> module in the previously created directory. The <code>'quotes'</code> part is the namespace for views of our module; you'll see that in action when we add the first real view in the advanced tutorial.

In addition to registering the views, we need to register our view mixin. For this, we need to inject the <code>Biigle\Services\Modules</code> class in the <code>boot</code> function. To keep things simple, here is how the service provider class should look like:

<pre><code>&lt;?php

namespace Biigle\Modules\Quotes;

use Biigle\Services\Modules;
use Illuminate\Support\ServiceProvider;

class QuotesServiceProvider extends ServiceProvider {

   /**
   * Bootstrap the application events.
   *
   * @param Modules $modules
   * @return void
   */
   public function boot(Modules $modules)
   {
      $this->loadViewsFrom(__DIR__.'/resources/views', 'quotes');
      $modules->register('module', ['viewMixins' => ['dashboardMain']]);
   }

   /**
   * Register the service provider.
   *
   * @return void
   */
   public function register()
   {
      //
   }
}
</code></pre>

Now refresh your BIIGLE dashboard and get inspired!

<blockquote>
   Smile, breathe, and go slowly.
   <footer>Thich Nhat Hanh</footer>
</blockquote>

## Conclusion

In this tutorial you have learned the basics of BIIGLE module development and how to extend existing BIIGLE views with custom view mixins. In a next tutorial we'll talk about implementing new routes and controllers, and how to properly test them using the BIIGLE testing environment. Further down the road are custom assets like CSS or the JavaScript of a custom client side application.

If you have any questions or are looking for examples, take a look at the <a href="http://laravel.com/docs/5.4/packages">Laravel documentation</a> on package development or the existing BIIGLE modules of your installation.
