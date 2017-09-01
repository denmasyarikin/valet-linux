<?php

namespace Valet;

use Valet\Contracts\PackageManager;
use Valet\Contracts\ServiceManager;

class DnsMasq
{
    public $pm;
    public $sm;
    public $cli;
    public $files;
    public $configPath;
    public $nmConfigPath;
    public $resolvedConfig;

    /**
     * Create a new DnsMasq instance.
     *
     * @param  PackageManager  $pm
     * @param  ServiceManager  $sm
     * @param  Filesystem  $files
     * @return void
     */
    public function __construct(PackageManager $pm, ServiceManager $sm, Filesystem $files, CommandLine $cli)
    {
        $this->pm    = $pm;
        $this->sm    = $sm;
        $this->cli   = $cli;
        $this->files = $files;
        $this->resolvconf   = '/etc/resolv.conf';
        $this->dnsmasqconf  = '/etc/dnsmasq.conf';
        $this->configPath   = '/etc/dnsmasq.d/valet';
        $this->dnsmasqOpts  = '/etc/dnsmasq.d/options';
        $this->nmConfigPath = '/etc/NetworkManager/conf.d/valet.conf';
        $this->resolvedConfigPath = '/etc/systemd/resolved.conf';
    }

    /**
     * Install and configure DnsMasq.
     *
     * @return void
     */
    private function lockResolvConf($lock = true)
    {
        $arg = $lock ? '+i' : '-i';

        $this->cli->run("chattr {$arg} {$this->resolvconf}", function ($code, $msg){
            warning($msg);
        });
    }

    /**
     * Install and configure DnsMasq.
     *
     * @return void
     */
    public function install($domain = 'dev')
    {
        $this->dnsmasqSetup();
        $this->fixResolved();
        $this->createCustomConfigFile($domain);
        $this->pm->nmRestart($this->sm);
        $this->sm->restart('dnsmasq');
    }

    /**
     * Append the custom DnsMasq configuration file to the main configuration file.
     *
     * @param  string  $domain
     * @return void
     */
    public function createCustomConfigFile($domain)
    {
        $this->files->putAsUser($this->configPath, 'address=/.'.$domain.'/127.0.0.1'.PHP_EOL);
    }

    /**
     * Fix systemd-resolved configuration.
     *
     * @return void
     */
    public function fixResolved()
    {
        $resolved = $this->resolvedConfigPath;

        $this->files->backup($resolved);
        $this->files->putAsUser($resolved, $this->files->get(__DIR__.'/../stubs/resolved.conf'));

        $this->sm->disable('systemd-resolved');
        $this->sm->stop('systemd-resolved');
    }

    /**
     * Setup dnsmasq with Network Manager.
     */
    public function dnsmasqSetup()
    {
        $this->pm->ensureInstalled('dnsmasq');
        $this->sm->enable('dnsmasq');

        $this->files->ensureDirExists('/etc/NetworkManager/conf.d');
        $this->files->ensureDirExists('/etc/dnsmasq.d');

        $this->lockResolvConf(false);

        $this->files->unlink('/etc/dnsmasq.d/network-manager');
        $this->files->backup($this->resolvconf);
        $this->files->backup($this->dnsmasqconf);

        $this->files->putAsUser($this->resolvconf, 'nameserver 127.0.0.1'.PHP_EOL);
        $this->files->putAsUser($this->dnsmasqconf, $this->files->get(__DIR__.'/../stubs/dnsmasq.conf'));
        $this->files->putAsUser($this->dnsmasqOpts, $this->files->get(__DIR__.'/../stubs/dnsmasq_options'));
        $this->files->putAsUser($this->nmConfigPath, $this->files->get(__DIR__.'/../stubs/networkmanager.conf'));

        $this->lockResolvConf();
    }

    /**
     * Update the domain used by DnsMasq.
     *
     * @param  string  $newDomain
     * @return void
     */
    public function updateDomain($oldDomain, $newDomain)
    {
        $this->createCustomConfigFile($newDomain);
        $this->sm->restart('dnsmasq');
    }

    /**
     * Delete the DnsMasq config file.
     *
     * @return void
     */
    public function uninstall()
    {
        $this->files->unlink($this->configPath);
        $this->files->unlink($this->dnsmasqOpts);
        $this->files->unlink($this->nmConfigPath);
        $this->files->restore($this->resolvedConfigPath);
        $this->lockResolvConf(false);
        $this->files->restore($this->resolvconf);
        $this->files->restore($this->dnsmasqconf);

        $this->pm->nmRestart($this->sm);
        $this->sm->restart('dnsmasq');

        info('Valet DNS changes have been rolled back');
        warning('If your system depended on systemd-resolved (like Ubuntu 17.04), please enable it manually');
    }
}
